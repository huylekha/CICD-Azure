using Shared.Domain.Models;

namespace PaymentService.Services;

public interface IAccountService
{
    Task<Account?> GetAccountAsync(Guid accountId);
    Task<Account> CreateAccountAsync(string accountNumber, string accountHolderName, decimal initialBalance = 0, string currency = "USD");
    Task<bool> UpdateAccountBalanceAsync(Guid accountId, decimal newBalance);
    Task<bool> DebitAccountAsync(Guid accountId, decimal amount);
    Task<bool> CreditAccountAsync(Guid accountId, decimal amount);
}

