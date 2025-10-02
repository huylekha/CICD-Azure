namespace Shared.Domain.Events;

public class TransferCommandReceived : BaseEvent
{
    public Guid TransactionId { get; set; }
    public Guid FromAccountId { get; set; }
    public Guid ToAccountId { get; set; }
    public decimal Amount { get; set; }
    public string Currency { get; set; } = string.Empty;
    public string? Description { get; set; }
}

public class MoneyDebited : BaseEvent
{
    public Guid TransactionId { get; set; }
    public Guid AccountId { get; set; }
    public decimal Amount { get; set; }
    public decimal NewBalance { get; set; }
    public string Currency { get; set; } = string.Empty;
}

public class MoneyCredited : BaseEvent
{
    public Guid TransactionId { get; set; }
    public Guid AccountId { get; set; }
    public decimal Amount { get; set; }
    public decimal NewBalance { get; set; }
    public string Currency { get; set; } = string.Empty;
}

public class TransferCompleted : BaseEvent
{
    public Guid TransactionId { get; set; }
    public Guid FromAccountId { get; set; }
    public Guid ToAccountId { get; set; }
    public decimal Amount { get; set; }
    public string Currency { get; set; } = string.Empty;
}

public class TransferFailed : BaseEvent
{
    public Guid TransactionId { get; set; }
    public Guid FromAccountId { get; set; }
    public Guid ToAccountId { get; set; }
    public decimal Amount { get; set; }
    public string Currency { get; set; } = string.Empty;
    public string FailureReason { get; set; } = string.Empty;
}

public class TransferRollbackRequested : BaseEvent
{
    public Guid TransactionId { get; set; }
    public Guid FromAccountId { get; set; }
    public Guid ToAccountId { get; set; }
    public decimal Amount { get; set; }
    public string Currency { get; set; } = string.Empty;
    public string RollbackReason { get; set; } = string.Empty;
}

public class MoneyRefunded : BaseEvent
{
    public Guid TransactionId { get; set; }
    public Guid AccountId { get; set; }
    public decimal Amount { get; set; }
    public decimal NewBalance { get; set; }
    public string Currency { get; set; } = string.Empty;
}

public class TransferRollbackCompleted : BaseEvent
{
    public Guid TransactionId { get; set; }
    public Guid FromAccountId { get; set; }
    public Guid ToAccountId { get; set; }
    public decimal Amount { get; set; }
    public string Currency { get; set; } = string.Empty;
}

