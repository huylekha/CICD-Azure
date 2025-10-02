using MediatR;

namespace Shared.Domain.Queries;

public class GetAccountQuery : BaseQuery<GetAccountResult>
{
    public Guid AccountId { get; set; }
}

public class GetAccountResult
{
    public Guid Id { get; set; }
    public string AccountNumber { get; set; } = string.Empty;
    public string AccountHolderName { get; set; } = string.Empty;
    public decimal Balance { get; set; }
    public string Currency { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class GetTransactionQuery : BaseQuery<GetTransactionResult>
{
    public Guid TransactionId { get; set; }
}

public class GetTransactionResult
{
    public Guid Id { get; set; }
    public Guid FromAccountId { get; set; }
    public Guid ToAccountId { get; set; }
    public decimal Amount { get; set; }
    public string Currency { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Status { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
    public DateTime? FailedAt { get; set; }
    public string? FailureReason { get; set; }
    public string? CorrelationId { get; set; }
}

public class GetAccountTransactionsQuery : BaseQuery<GetAccountTransactionsResult>
{
    public Guid AccountId { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}

public class GetAccountTransactionsResult
{
    public List<GetTransactionResult> Transactions { get; set; } = new();
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int TotalPages => (int)Math.Ceiling((double)TotalCount / PageSize);
}

