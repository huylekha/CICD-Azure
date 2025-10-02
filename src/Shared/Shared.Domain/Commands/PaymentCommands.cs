using MediatR;

namespace Shared.Domain.Commands;

public class TransferMoneyCommand : BaseCommand<TransferMoneyResult>
{
    public Guid FromAccountId { get; set; }
    public Guid ToAccountId { get; set; }
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "USD";
    public string? Description { get; set; }
}

public class TransferMoneyResult
{
    public bool Success { get; set; }
    public Guid TransactionId { get; set; }
    public string? ErrorMessage { get; set; }
}

public class RollbackTransferCommand : BaseCommand<RollbackTransferResult>
{
    public Guid TransactionId { get; set; }
    public string Reason { get; set; } = string.Empty;
}

public class RollbackTransferResult
{
    public bool Success { get; set; }
    public string? ErrorMessage { get; set; }
}

