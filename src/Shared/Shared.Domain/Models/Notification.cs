using System.ComponentModel.DataAnnotations;

namespace Shared.Domain.Models;

public class Notification
{
    public Guid Id { get; set; }
    
    [Required]
    [MaxLength(100)]
    public string Title { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(1000)]
    public string Message { get; set; } = string.Empty;
    
    [Required]
    public NotificationType Type { get; set; }
    
    [Required]
    public NotificationPriority Priority { get; set; }
    
    [Required]
    [MaxLength(255)]
    public string Recipient { get; set; } = string.Empty; // Email or Phone number
    
    [MaxLength(50)]
    public string? RecipientName { get; set; }
    
    public NotificationStatus Status { get; set; } = NotificationStatus.Pending;
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public DateTime? SentAt { get; set; }
    
    public DateTime? FailedAt { get; set; }
    
    [MaxLength(500)]
    public string? FailureReason { get; set; }
    
    [MaxLength(100)]
    public string? CorrelationId { get; set; }
    
    // Additional metadata
    [MaxLength(1000)]
    public string? Metadata { get; set; } // JSON string for additional data
}

public enum NotificationType
{
    Email = 1,
    Sms = 2,
    Push = 3,
    InApp = 4
}

public enum NotificationPriority
{
    Low = 1,
    Normal = 2,
    High = 3,
    Critical = 4
}

public enum NotificationStatus
{
    Pending = 1,
    Sent = 2,
    Failed = 3,
    Cancelled = 4
}

