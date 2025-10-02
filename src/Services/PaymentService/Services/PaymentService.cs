using MediatR;
using Microsoft.EntityFrameworkCore;
using PaymentService.Data;
using Serilog;
using Shared.Domain.Commands;
using Shared.Domain.Events;
using Shared.Domain.Models;
using Shared.Domain.Queries;
using MassTransit;

namespace PaymentService.Services;

public class PaymentService : IPaymentService
{
    private readonly PaymentDbContext _context;
    private readonly IPublishEndpoint _publishEndpoint;
    private readonly Serilog.ILogger _logger;

    public PaymentService(
        PaymentDbContext context,
        IPublishEndpoint publishEndpoint,
        Serilog.ILogger logger)
    {
        _context = context;
        _publishEndpoint = publishEndpoint;
        _logger = logger;
    }

    public async Task<TransferMoneyResult> TransferMoneyAsync(TransferMoneyCommand command)
    {
        using var transaction = await _context.Database.BeginTransactionAsync();
        
        try
        {
            _logger.Information("Starting money transfer: {FromAccountId} -> {ToAccountId}, Amount: {Amount} {Currency}",
                command.FromAccountId, command.ToAccountId, command.Amount, command.Currency);

            // Get accounts with optimistic concurrency
            var fromAccount = await _context.Accounts
                .FirstOrDefaultAsync(a => a.Id == command.FromAccountId && a.IsActive);
            
            var toAccount = await _context.Accounts
                .FirstOrDefaultAsync(a => a.Id == command.ToAccountId && a.IsActive);

            if (fromAccount == null)
            {
                _logger.Warning("From account not found: {AccountId}", command.FromAccountId);
                return new TransferMoneyResult
                {
                    Success = false,
                    ErrorMessage = "From account not found or inactive"
                };
            }

            if (toAccount == null)
            {
                _logger.Warning("To account not found: {AccountId}", command.ToAccountId);
                return new TransferMoneyResult
                {
                    Success = false,
                    ErrorMessage = "To account not found or inactive"
                };
            }

            if (fromAccount.Balance < command.Amount)
            {
                _logger.Warning("Insufficient balance: Account {AccountId}, Balance: {Balance}, Required: {Amount}",
                    command.FromAccountId, fromAccount.Balance, command.Amount);
                return new TransferMoneyResult
                {
                    Success = false,
                    ErrorMessage = "Insufficient balance"
                };
            }

            // Create transaction record
            var transactionRecord = new Transaction
            {
                Id = Guid.NewGuid(),
                FromAccountId = command.FromAccountId,
                ToAccountId = command.ToAccountId,
                Amount = command.Amount,
                Currency = command.Currency,
                Description = command.Description,
                Status = TransactionStatus.Processing,
                Type = TransactionType.Transfer,
                CorrelationId = command.CorrelationId
            };

            _context.Transactions.Add(transactionRecord);

            // Debit from account
            fromAccount.Balance -= command.Amount;
            fromAccount.UpdatedAt = DateTime.UtcNow;
            fromAccount.Version = Guid.NewGuid().ToString();

            // Credit to account
            toAccount.Balance += command.Amount;
            toAccount.UpdatedAt = DateTime.UtcNow;
            toAccount.Version = Guid.NewGuid().ToString();

            await _context.SaveChangesAsync();

            // Publish events
            await _publishEndpoint.Publish(new MoneyDebited
            {
                TransactionId = transactionRecord.Id,
                AccountId = fromAccount.Id,
                Amount = command.Amount,
                NewBalance = fromAccount.Balance,
                Currency = command.Currency,
                CorrelationId = command.CorrelationId
            });

            await _publishEndpoint.Publish(new MoneyCredited
            {
                TransactionId = transactionRecord.Id,
                AccountId = toAccount.Id,
                Amount = command.Amount,
                NewBalance = toAccount.Balance,
                Currency = command.Currency,
                CorrelationId = command.CorrelationId
            });

            // Update transaction status
            transactionRecord.Status = TransactionStatus.Completed;
            transactionRecord.CompletedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            await _publishEndpoint.Publish(new TransferCompleted
            {
                TransactionId = transactionRecord.Id,
                FromAccountId = command.FromAccountId,
                ToAccountId = command.ToAccountId,
                Amount = command.Amount,
                Currency = command.Currency,
                CorrelationId = command.CorrelationId
            });

            await transaction.CommitAsync();

            _logger.Information("Money transfer completed successfully: {TransactionId}", transactionRecord.Id);

            return new TransferMoneyResult
            {
                Success = true,
                TransactionId = transactionRecord.Id
            };
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            _logger.Error(ex, "Error during money transfer: {FromAccountId} -> {ToAccountId}",
                command.FromAccountId, command.ToAccountId);

            return new TransferMoneyResult
            {
                Success = false,
                ErrorMessage = "Transfer failed due to an internal error"
            };
        }
    }

    public async Task<RollbackTransferResult> RollbackTransferAsync(RollbackTransferCommand command)
    {
        using var transaction = await _context.Database.BeginTransactionAsync();
        
        try
        {
            _logger.Information("Starting transfer rollback: {TransactionId}, Reason: {Reason}",
                command.TransactionId, command.Reason);

            var transactionRecord = await _context.Transactions
                .FirstOrDefaultAsync(t => t.Id == command.TransactionId);

            if (transactionRecord == null)
            {
                _logger.Warning("Transaction not found for rollback: {TransactionId}", command.TransactionId);
                return new RollbackTransferResult
                {
                    Success = false,
                    ErrorMessage = "Transaction not found"
                };
            }

            if (transactionRecord.Status != TransactionStatus.Completed)
            {
                _logger.Warning("Cannot rollback transaction in status: {Status}", transactionRecord.Status);
                return new RollbackTransferResult
                {
                    Success = false,
                    ErrorMessage = "Transaction is not in a rollbackable state"
                };
            }

            // Get accounts
            var fromAccount = await _context.Accounts.FindAsync(transactionRecord.FromAccountId);
            var toAccount = await _context.Accounts.FindAsync(transactionRecord.ToAccountId);

            if (fromAccount == null || toAccount == null)
            {
                _logger.Error("Accounts not found for rollback: From={FromAccountId}, To={ToAccountId}",
                    transactionRecord.FromAccountId, transactionRecord.ToAccountId);
                return new RollbackTransferResult
                {
                    Success = false,
                    ErrorMessage = "Accounts not found"
                };
            }

            // Reverse the transaction
            fromAccount.Balance += transactionRecord.Amount;
            fromAccount.UpdatedAt = DateTime.UtcNow;
            fromAccount.Version = Guid.NewGuid().ToString();

            toAccount.Balance -= transactionRecord.Amount;
            toAccount.UpdatedAt = DateTime.UtcNow;
            toAccount.Version = Guid.NewGuid().ToString();

            transactionRecord.Status = TransactionStatus.RolledBack;
            transactionRecord.FailedAt = DateTime.UtcNow;
            transactionRecord.FailureReason = command.Reason;

            await _context.SaveChangesAsync();

            // Publish rollback events
            await _publishEndpoint.Publish(new MoneyRefunded
            {
                TransactionId = transactionRecord.Id,
                AccountId = fromAccount.Id,
                Amount = transactionRecord.Amount,
                NewBalance = fromAccount.Balance,
                Currency = transactionRecord.Currency,
                CorrelationId = command.CorrelationId
            });

            await _publishEndpoint.Publish(new TransferRollbackCompleted
            {
                TransactionId = transactionRecord.Id,
                FromAccountId = transactionRecord.FromAccountId,
                ToAccountId = transactionRecord.ToAccountId,
                Amount = transactionRecord.Amount,
                Currency = transactionRecord.Currency,
                CorrelationId = command.CorrelationId
            });

            await transaction.CommitAsync();

            _logger.Information("Transfer rollback completed successfully: {TransactionId}", transactionRecord.Id);

            return new RollbackTransferResult
            {
                Success = true
            };
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            _logger.Error(ex, "Error during transfer rollback: {TransactionId}", command.TransactionId);

            return new RollbackTransferResult
            {
                Success = false,
                ErrorMessage = "Rollback failed due to an internal error"
            };
        }
    }

    public async Task<GetAccountResult> GetAccountAsync(GetAccountQuery query)
    {
        var account = await _context.Accounts
            .FirstOrDefaultAsync(a => a.Id == query.AccountId);

        if (account == null)
        {
            return null!;
        }

        return new GetAccountResult
        {
            Id = account.Id,
            AccountNumber = account.AccountNumber,
            AccountHolderName = account.AccountHolderName,
            Balance = account.Balance,
            Currency = account.Currency,
            IsActive = account.IsActive,
            CreatedAt = account.CreatedAt,
            UpdatedAt = account.UpdatedAt
        };
    }

    public async Task<GetTransactionResult> GetTransactionAsync(GetTransactionQuery query)
    {
        var transaction = await _context.Transactions
            .FirstOrDefaultAsync(t => t.Id == query.TransactionId);

        if (transaction == null)
        {
            return null!;
        }

        return new GetTransactionResult
        {
            Id = transaction.Id,
            FromAccountId = transaction.FromAccountId,
            ToAccountId = transaction.ToAccountId,
            Amount = transaction.Amount,
            Currency = transaction.Currency,
            Description = transaction.Description,
            Status = transaction.Status.ToString(),
            Type = transaction.Type.ToString(),
            CreatedAt = transaction.CreatedAt,
            CompletedAt = transaction.CompletedAt,
            FailedAt = transaction.FailedAt,
            FailureReason = transaction.FailureReason,
            CorrelationId = transaction.CorrelationId
        };
    }

    public async Task<GetAccountTransactionsResult> GetAccountTransactionsAsync(GetAccountTransactionsQuery query)
    {
        var queryable = _context.Transactions
            .Where(t => t.FromAccountId == query.AccountId || t.ToAccountId == query.AccountId)
            .OrderByDescending(t => t.CreatedAt);

        var totalCount = await queryable.CountAsync();

        var transactions = await queryable
            .Skip((query.Page - 1) * query.PageSize)
            .Take(query.PageSize)
            .Select(t => new GetTransactionResult
            {
                Id = t.Id,
                FromAccountId = t.FromAccountId,
                ToAccountId = t.ToAccountId,
                Amount = t.Amount,
                Currency = t.Currency,
                Description = t.Description,
                Status = t.Status.ToString(),
                Type = t.Type.ToString(),
                CreatedAt = t.CreatedAt,
                CompletedAt = t.CompletedAt,
                FailedAt = t.FailedAt,
                FailureReason = t.FailureReason,
                CorrelationId = t.CorrelationId
            })
            .ToListAsync();

        return new GetAccountTransactionsResult
        {
            Transactions = transactions,
            TotalCount = totalCount,
            Page = query.Page,
            PageSize = query.PageSize
        };
    }
}

