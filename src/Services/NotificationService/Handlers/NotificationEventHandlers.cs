using MassTransit;
using NotificationService.Services;
using Serilog;
using Shared.Domain.Events;
using Microsoft.Extensions.Logging;

namespace NotificationService.Handlers;

public class NotificationRequestedHandler : IConsumer<NotificationRequested>
{
    private readonly INotificationService _notificationService;
    private readonly Microsoft.Extensions.Logging.ILogger _logger;

    public NotificationRequestedHandler(INotificationService notificationService, Microsoft.Extensions.Logging.ILogger logger)
    {
        _notificationService = notificationService;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<NotificationRequested> context)
    {
        var message = context.Message;
        
        _logger.Information("Processing notification request: {NotificationId}, Type: {Type}",
            message.NotificationId, message.Type);

        try
        {
            var notification = await _notificationService.CreateNotificationAsync(message);
            await _notificationService.SendNotificationAsync(notification.Id);
        }
        catch (Exception ex)
        {
            _logger.Error(ex, "Error processing notification request: {NotificationId}", message.NotificationId);
            throw;
        }
    }
}

public class TransferCompletedHandler : IConsumer<TransferCompleted>
{
    private readonly INotificationService _notificationService;
    private readonly IPublishEndpoint _publishEndpoint;
    private readonly Microsoft.Extensions.Logging.ILogger _logger;

    public TransferCompletedHandler(
        INotificationService notificationService,
        IPublishEndpoint publishEndpoint,
        Microsoft.Extensions.Logging.ILogger logger)
    {
        _notificationService = notificationService;
        _publishEndpoint = publishEndpoint;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<TransferCompleted> context)
    {
        var message = context.Message;
        
        _logger.Information("Processing transfer completed notification: {TransactionId}",
            message.TransactionId);

        try
        {
            // Create notification for successful transfer
            var notificationRequested = new NotificationRequested
            {
                NotificationId = Guid.NewGuid(),
                RecipientEmail = "user@example.com", // In real app, get from user profile
                Subject = "Transfer Completed",
                Message = $"Your transfer of {message.Amount} {message.Currency} has been completed successfully.",
                Type = NotificationType.Email,
                Priority = NotificationPriority.Normal,
                CorrelationId = message.CorrelationId
            };

            await _publishEndpoint.Publish(notificationRequested);
        }
        catch (Exception ex)
        {
            _logger.Error(ex, "Error processing transfer completed notification: {TransactionId}", message.TransactionId);
            throw;
        }
    }
}

public class TransferFailedHandler : IConsumer<TransferFailed>
{
    private readonly INotificationService _notificationService;
    private readonly IPublishEndpoint _publishEndpoint;
    private readonly Microsoft.Extensions.Logging.ILogger _logger;

    public TransferFailedHandler(
        INotificationService notificationService,
        IPublishEndpoint publishEndpoint,
        Microsoft.Extensions.Logging.ILogger logger)
    {
        _notificationService = notificationService;
        _publishEndpoint = publishEndpoint;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<TransferFailed> context)
    {
        var message = context.Message;
        
        _logger.Information("Processing transfer failed notification: {TransactionId}",
            message.TransactionId);

        try
        {
            // Create notification for failed transfer
            var notificationRequested = new NotificationRequested
            {
                NotificationId = Guid.NewGuid(),
                RecipientEmail = "user@example.com", // In real app, get from user profile
                Subject = "Transfer Failed",
                Message = $"Your transfer of {message.Amount} {message.Currency} has failed. Reason: {message.FailureReason}",
                Type = NotificationType.Email,
                Priority = NotificationPriority.High,
                CorrelationId = message.CorrelationId
            };

            await _publishEndpoint.Publish(notificationRequested);
        }
        catch (Exception ex)
        {
            _logger.Error(ex, "Error processing transfer failed notification: {TransactionId}", message.TransactionId);
            throw;
        }
    }
}

