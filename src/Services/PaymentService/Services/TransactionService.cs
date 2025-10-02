using Microsoft.EntityFrameworkCore;
using PaymentService.Data;
using Shared.Domain.Models;

namespace PaymentService.Services;

public class TransactionService : ITransactionService
{
    private readonly PaymentDbContext _context;

    public TransactionService(PaymentDbContext context)
    {
        _context = context;
    }

    public async Task<Transaction> CreateTransactionAsync(Guid fromAccountId, Guid toAccountId, decimal amount, string currency, string? description = null)
    {
        var transaction = new Transaction
        {
            Id = Guid.NewGuid(),
            FromAccountId = fromAccountId,
            ToAccountId = toAccountId,
            Amount = amount,
            Currency = currency,
            Description = description,
            Status = TransactionStatus.Pending,
            Type = TransactionType.Transfer,
            CreatedAt = DateTime.UtcNow
        };

        _context.Transactions.Add(transaction);
        await _context.SaveChangesAsync();

        return transaction;
    }

    public async Task<Transaction?> GetTransactionAsync(Guid transactionId)
    {
        return await _context.Transactions
            .FirstOrDefaultAsync(t => t.Id == transactionId);
    }

    public async Task UpdateTransactionStatusAsync(Guid transactionId, TransactionStatus status, string? failureReason = null)
    {
        var transaction = await _context.Transactions
            .FirstOrDefaultAsync(t => t.Id == transactionId);

        if (transaction != null)
        {
            transaction.Status = status;
            
            if (status == TransactionStatus.Completed)
            {
                transaction.CompletedAt = DateTime.UtcNow;
            }
            else if (status == TransactionStatus.Failed)
            {
                transaction.FailedAt = DateTime.UtcNow;
                transaction.FailureReason = failureReason;
            }

            await _context.SaveChangesAsync();
        }
    }
}

