using Microsoft.EntityFrameworkCore;
using PaymentService.Data;
using Shared.Domain.Models;

namespace PaymentService.Services;

public class AccountService : IAccountService
{
    private readonly PaymentDbContext _context;

    public AccountService(PaymentDbContext context)
    {
        _context = context;
    }

    public async Task<Account?> GetAccountAsync(Guid accountId)
    {
        return await _context.Accounts
            .FirstOrDefaultAsync(a => a.Id == accountId);
    }

    public async Task<Account> CreateAccountAsync(string accountNumber, string accountHolderName, decimal initialBalance = 0, string currency = "USD")
    {
        var account = new Account
        {
            Id = Guid.NewGuid(),
            AccountNumber = accountNumber,
            AccountHolderName = accountHolderName,
            Balance = initialBalance,
            Currency = currency,
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow,
            Version = Guid.NewGuid().ToString()
        };

        _context.Accounts.Add(account);
        await _context.SaveChangesAsync();

        return account;
    }

    public async Task<bool> UpdateAccountBalanceAsync(Guid accountId, decimal newBalance)
    {
        var account = await _context.Accounts.FindAsync(accountId);
        if (account == null) return false;

        account.Balance = newBalance;
        account.UpdatedAt = DateTime.UtcNow;
        account.Version = Guid.NewGuid().ToString();

        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DebitAccountAsync(Guid accountId, decimal amount)
    {
        var account = await _context.Accounts.FindAsync(accountId);
        if (account == null || account.Balance < amount) return false;

        account.Balance -= amount;
        account.UpdatedAt = DateTime.UtcNow;
        account.Version = Guid.NewGuid().ToString();

        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> CreditAccountAsync(Guid accountId, decimal amount)
    {
        var account = await _context.Accounts.FindAsync(accountId);
        if (account == null) return false;

        account.Balance += amount;
        account.UpdatedAt = DateTime.UtcNow;
        account.Version = Guid.NewGuid().ToString();

        await _context.SaveChangesAsync();
        return true;
    }
}

