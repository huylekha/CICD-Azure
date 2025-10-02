namespace Shared.Domain.Events;

public class NotificationRequested : BaseEvent
{
    public Guid NotificationId { get; set; }
    public string RecipientEmail { get; set; } = string.Empty;
    public string RecipientPhone { get; set; } = string.Empty;
    public string Subject { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public NotificationType Type { get; set; }
    public NotificationPriority Priority { get; set; } = NotificationPriority.Normal;
}

public class NotificationSent : BaseEvent
{
    public Guid NotificationId { get; set; }
    public string RecipientEmail { get; set; } = string.Empty;
    public string RecipientPhone { get; set; } = string.Empty;
    public string Subject { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public NotificationType Type { get; set; }
    public DateTime SentAt { get; set; } = DateTime.UtcNow;
}

public class NotificationFailed : BaseEvent
{
    public Guid NotificationId { get; set; }
    public string RecipientEmail { get; set; } = string.Empty;
    public string RecipientPhone { get; set; } = string.Empty;
    public string Subject { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public NotificationType Type { get; set; }
    public string FailureReason { get; set; } = string.Empty;
    public DateTime FailedAt { get; set; } = DateTime.UtcNow;
}

public enum NotificationType
{
    Email,
    SMS,
    Push,
    InApp
}

public enum NotificationPriority
{
    Low,
    Normal,
    High,
    Critical
}

