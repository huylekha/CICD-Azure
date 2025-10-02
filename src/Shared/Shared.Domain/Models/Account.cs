using System.ComponentModel.DataAnnotations;

namespace Shared.Domain.Models;

public class Account
{
    public Guid Id { get; set; }
    
    [Required]
    [StringLength(50)]
    public string AccountNumber { get; set; } = string.Empty;
    
    [Required]
    [StringLength(100)]
    public string AccountHolderName { get; set; } = string.Empty;
    
    public decimal Balance { get; set; }
    
    [Required]
    [StringLength(3)]
    public string Currency { get; set; } = "USD";
    
    public bool IsActive { get; set; } = true;
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    
    public string Version { get; set; } = string.Empty; // For optimistic concurrency
}

