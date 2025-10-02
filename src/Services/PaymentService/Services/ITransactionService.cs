using Shared.Domain.Models;

namespace PaymentService.Services;

public interface ITransactionService
{
    Task<Transaction> CreateTransactionAsync(Guid fromAccountId, Guid toAccountId, decimal amount, string currency, string? description = null);
    Task<Transaction?> GetTransactionAsync(Guid transactionId);
    Task UpdateTransactionStatusAsync(Guid transactionId, TransactionStatus status, string? failureReason = null);
}

