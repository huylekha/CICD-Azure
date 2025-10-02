using Shared.Domain.Events;

using Shared.Domain.Models;

namespace NotificationService.Services;

public interface INotificationService
{
    Task<Notification> CreateNotificationAsync(NotificationRequested notificationRequested);
    Task<bool> SendNotificationAsync(Guid notificationId);
    Task<bool> MarkNotificationAsSentAsync(Guid notificationId);
    Task<bool> MarkNotificationAsFailedAsync(Guid notificationId, string failureReason);
    Task<Notification?> GetNotificationAsync(Guid notificationId);
}

