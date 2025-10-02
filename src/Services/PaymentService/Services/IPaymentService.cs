using Shared.Domain.Commands;
using Shared.Domain.Queries;

namespace PaymentService.Services;

public interface IPaymentService
{
    Task<TransferMoneyResult> TransferMoneyAsync(TransferMoneyCommand command);
    Task<RollbackTransferResult> RollbackTransferAsync(RollbackTransferCommand command);
    Task<GetAccountResult> GetAccountAsync(GetAccountQuery query);
    Task<GetTransactionResult> GetTransactionAsync(GetTransactionQuery query);
    Task<GetAccountTransactionsResult> GetAccountTransactionsAsync(GetAccountTransactionsQuery query);
}

