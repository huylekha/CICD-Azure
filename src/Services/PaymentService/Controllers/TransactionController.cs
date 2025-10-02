using MediatR;
using Microsoft.AspNetCore.Mvc;
using Shared.Domain.Queries;

namespace PaymentService.Controllers;

[ApiController]
[Route("api/[controller]")]
public class TransactionController : ControllerBase
{
    private readonly IMediator _mediator;
    private readonly ILogger<TransactionController> _logger;

    public TransactionController(IMediator mediator, ILogger<TransactionController> logger)
    {
        _mediator = mediator;
        _logger = logger;
    }

    [HttpGet("{transactionId}")]
    public async Task<IActionResult> GetTransaction(Guid transactionId)
    {
        try
        {
            var query = new GetTransactionQuery { TransactionId = transactionId };
            var result = await _mediator.Send(query);

            if (result == null)
            {
                return NotFound();
            }

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving transaction {TransactionId}", transactionId);
            return StatusCode(500, new { error = "Internal server error" });
        }
    }

    [HttpGet]
    public async Task<IActionResult> GetAllTransactions([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        try
        {
            // Mock data for demo - in real app, this would be a proper query
            var mockTransactions = new[]
            {
                new GetTransactionResult
                {
                    Id = Guid.Parse("660e8400-e29b-41d4-a716-446655440001"),
                    FromAccountId = Guid.Parse("550e8400-e29b-41d4-a716-446655440001"),
                    ToAccountId = Guid.Parse("550e8400-e29b-41d4-a716-446655440002"),
                    Amount = 1000,
                    Currency = "USD",
                    Description = "Payment for services",
                    Status = "Completed",
                    Type = "Transfer",
                    CreatedAt = DateTime.UtcNow.AddDays(-1),
                    CompletedAt = DateTime.UtcNow.AddDays(-1),
                    CorrelationId = "corr-001"
                },
                new GetTransactionResult
                {
                    Id = Guid.Parse("660e8400-e29b-41d4-a716-446655440002"),
                    FromAccountId = Guid.Parse("550e8400-e29b-41d4-a716-446655440002"),
                    ToAccountId = Guid.Parse("550e8400-e29b-41d4-a716-446655440003"),
                    Amount = 500,
                    Currency = "USD",
                    Description = "Monthly rent payment",
                    Status = "Processing",
                    Type = "Transfer",
                    CreatedAt = DateTime.UtcNow.AddHours(-2),
                    CorrelationId = "corr-002"
                },
                new GetTransactionResult
                {
                    Id = Guid.Parse("660e8400-e29b-41d4-a716-446655440003"),
                    FromAccountId = Guid.Parse("550e8400-e29b-41d4-a716-446655440003"),
                    ToAccountId = Guid.Parse("550e8400-e29b-41d4-a716-446655440001"),
                    Amount = 2500,
                    Currency = "USD",
                    Description = "Refund for cancelled order",
                    Status = "Completed",
                    Type = "Refund",
                    CreatedAt = DateTime.UtcNow.AddHours(-3),
                    CompletedAt = DateTime.UtcNow.AddHours(-3),
                    CorrelationId = "corr-003"
                },
                new GetTransactionResult
                {
                    Id = Guid.Parse("660e8400-e29b-41d4-a716-446655440004"),
                    FromAccountId = Guid.Parse("550e8400-e29b-41d4-a716-446655440004"),
                    ToAccountId = Guid.Parse("550e8400-e29b-41d4-a716-446655440005"),
                    Amount = 750,
                    Currency = "USD",
                    Description = "Failed transfer - insufficient funds",
                    Status = "Failed",
                    Type = "Transfer",
                    CreatedAt = DateTime.UtcNow.AddHours(-4),
                    FailedAt = DateTime.UtcNow.AddHours(-4),
                    FailureReason = "Insufficient balance",
                    CorrelationId = "corr-004"
                },
                new GetTransactionResult
                {
                    Id = Guid.Parse("660e8400-e29b-41d4-a716-446655440005"),
                    FromAccountId = Guid.Parse("550e8400-e29b-41d4-a716-446655440005"),
                    ToAccountId = Guid.Parse("550e8400-e29b-41d4-a716-446655440001"),
                    Amount = 2000,
                    Currency = "USD",
                    Description = "Business payment",
                    Status = "RolledBack",
                    Type = "Transfer",
                    CreatedAt = DateTime.UtcNow.AddHours(-5),
                    FailedAt = DateTime.UtcNow.AddHours(-5),
                    FailureReason = "Notification service failure",
                    CorrelationId = "corr-005"
                }
            };

            var result = new GetAccountTransactionsResult
            {
                Transactions = mockTransactions.Skip((page - 1) * pageSize).Take(pageSize).ToList(),
                TotalCount = mockTransactions.Length,
                Page = page,
                PageSize = pageSize
            };

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving transactions");
            return StatusCode(500, new { error = "Internal server error" });
        }
    }

    [HttpGet("account/{accountId}")]
    public async Task<IActionResult> GetAccountTransactions(
        Guid accountId,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        try
        {
            var query = new GetAccountTransactionsQuery
            {
                AccountId = accountId,
                Page = page,
                PageSize = pageSize
            };

            var result = await _mediator.Send(query);
            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving transactions for account {AccountId}", accountId);
            return StatusCode(500, new { error = "Internal server error" });
        }
    }
}
