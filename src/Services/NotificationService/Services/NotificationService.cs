using MassTransit;
using Microsoft.EntityFrameworkCore;
using NotificationService.Data;
using Serilog;
using Shared.Domain.Events;
using Shared.Domain.Models;

namespace NotificationService.Services;

public class NotificationService : INotificationService
{
    private readonly NotificationDbContext _context;
    private readonly IEmailService _emailService;
    private readonly ISmsService _smsService;
    private readonly IPublishEndpoint _publishEndpoint;
    private readonly Serilog.ILogger _logger;

    public NotificationService(
        NotificationDbContext context,
        IEmailService emailService,
        ISmsService smsService,
        IPublishEndpoint publishEndpoint,
        Serilog.ILogger logger)
    {
        _context = context;
        _emailService = emailService;
        _smsService = smsService;
        _publishEndpoint = publishEndpoint;
        _logger = logger;
    }

    public async Task<Notification> CreateNotificationAsync(NotificationRequested notificationRequested)
    {
        var notification = new Notification
        {
            Id = notificationRequested.NotificationId,
            RecipientEmail = notificationRequested.RecipientEmail,
            RecipientPhone = notificationRequested.RecipientPhone,
            Subject = notificationRequested.Subject,
            Message = notificationRequested.Message,
            Type = notificationRequested.Type,
            Priority = notificationRequested.Priority,
            Status = NotificationStatus.Pending,
            CreatedAt = DateTime.UtcNow,
            CorrelationId = notificationRequested.CorrelationId
        };

        _context.Notifications.Add(notification);
        await _context.SaveChangesAsync();

        _logger.Information("Notification created: {NotificationId}, Type: {Type}, Recipient: {Recipient}",
            notification.Id, notification.Type, notification.RecipientEmail);

        return notification;
    }

    public async Task<bool> SendNotificationAsync(Guid notificationId)
    {
        var notification = await _context.Notifications
            .FirstOrDefaultAsync(n => n.Id == notificationId);

        if (notification == null)
        {
            _logger.Warning("Notification not found: {NotificationId}", notificationId);
            return false;
        }

        try
        {
            bool success = false;

            switch (notification.Type)
            {
                case NotificationType.Email:
                    success = await _emailService.SendEmailAsync(
                        notification.RecipientEmail,
                        notification.Subject,
                        notification.Message);
                    break;

                case NotificationType.SMS:
                    success = await _smsService.SendSmsAsync(
                        notification.RecipientPhone,
                        notification.Message);
                    break;

                default:
                    _logger.Warning("Unsupported notification type: {Type}", notification.Type);
                    return false;
            }

            if (success)
            {
                await MarkNotificationAsSentAsync(notificationId);
                await _publishEndpoint.Publish(new NotificationSent
                {
                    NotificationId = notification.Id,
                    RecipientEmail = notification.RecipientEmail,
                    RecipientPhone = notification.RecipientPhone,
                    Subject = notification.Subject,
                    Message = notification.Message,
                    Type = notification.Type,
                    SentAt = DateTime.UtcNow,
                    CorrelationId = notification.CorrelationId
                });

                _logger.Information("Notification sent successfully: {NotificationId}", notificationId);
                return true;
            }
            else
            {
                await MarkNotificationAsFailedAsync(notificationId, "Failed to send notification");
                return false;
            }
        }
        catch (Exception ex)
        {
            _logger.Error(ex, "Error sending notification: {NotificationId}", notificationId);
            await MarkNotificationAsFailedAsync(notificationId, ex.Message);
            return false;
        }
    }

    public async Task<bool> MarkNotificationAsSentAsync(Guid notificationId)
    {
        var notification = await _context.Notifications
            .FirstOrDefaultAsync(n => n.Id == notificationId);

        if (notification == null) return false;

        notification.Status = NotificationStatus.Sent;
        notification.SentAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> MarkNotificationAsFailedAsync(Guid notificationId, string failureReason)
    {
        var notification = await _context.Notifications
            .FirstOrDefaultAsync(n => n.Id == notificationId);

        if (notification == null) return false;

        notification.Status = NotificationStatus.Failed;
        notification.FailedAt = DateTime.UtcNow;
        notification.FailureReason = failureReason;

        await _context.SaveChangesAsync();

        await _publishEndpoint.Publish(new NotificationFailed
        {
            NotificationId = notification.Id,
            RecipientEmail = notification.RecipientEmail,
            RecipientPhone = notification.RecipientPhone,
            Subject = notification.Subject,
            Message = notification.Message,
            Type = notification.Type,
            FailureReason = failureReason,
            FailedAt = DateTime.UtcNow,
            CorrelationId = notification.CorrelationId
        });

        return true;
    }

    public async Task<Notification?> GetNotificationAsync(Guid notificationId)
    {
        return await _context.Notifications
            .FirstOrDefaultAsync(n => n.Id == notificationId);
    }
}

