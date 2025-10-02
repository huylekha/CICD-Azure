using System.ComponentModel.DataAnnotations;

namespace Shared.Domain.Models;

public class Transaction
{
    public Guid Id { get; set; }
    
    [Required]
    public Guid FromAccountId { get; set; }
    
    [Required]
    public Guid ToAccountId { get; set; }
    
    public decimal Amount { get; set; }
    
    [Required]
    [StringLength(3)]
    public string Currency { get; set; } = "USD";
    
    [StringLength(500)]
    public string? Description { get; set; }
    
    public TransactionStatus Status { get; set; } = TransactionStatus.Pending;
    
    public TransactionType Type { get; set; } = TransactionType.Transfer;
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public DateTime? CompletedAt { get; set; }
    
    public DateTime? FailedAt { get; set; }
    
    [StringLength(1000)]
    public string? FailureReason { get; set; }
    
    public string? CorrelationId { get; set; } // For saga tracking
}

public enum TransactionStatus
{
    Pending,
    Processing,
    Completed,
    Failed,
    Cancelled,
    RolledBack
}

public enum TransactionType
{
    Transfer,
    Deposit,
    Withdrawal,
    Refund
}

