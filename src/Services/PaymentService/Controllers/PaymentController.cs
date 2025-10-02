using MediatR;
using Microsoft.AspNetCore.Mvc;
using Shared.Domain.Commands;
using Shared.Domain.Queries;

namespace PaymentService.Controllers;

/// <summary>
/// Payment Controller for managing money transfers and payment operations
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class PaymentController : ControllerBase
{
    private readonly IMediator _mediator;
    private readonly ILogger<PaymentController> _logger;

    public PaymentController(IMediator mediator, ILogger<PaymentController> logger)
    {
        _mediator = mediator;
        _logger = logger;
    }

    /// <summary>
    /// Transfer money between accounts
    /// </summary>
    /// <param name="command">Transfer money command containing from/to account IDs, amount, and currency</param>
    /// <returns>Transfer result with success status and transaction ID</returns>
    /// <response code="200">Transfer completed successfully</response>
    /// <response code="400">Invalid request or insufficient funds</response>
    /// <response code="500">Internal server error</response>
    [HttpPost("transfer")]
    [ProducesResponseType(typeof(TransferMoneyResult), 200)]
    [ProducesResponseType(400)]
    [ProducesResponseType(500)]
    public async Task<IActionResult> TransferMoney([FromBody] TransferMoneyCommand command)
    {
        try
        {
            command.CorrelationId = Guid.NewGuid().ToString();
            var result = await _mediator.Send(command);

            if (result.Success)
            {
                return Ok(result);
            }

            return BadRequest(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing transfer money request");
            return StatusCode(500, new { error = "Internal server error" });
        }
    }

    [HttpPost("rollback")]
    public async Task<IActionResult> RollbackTransfer([FromBody] RollbackTransferCommand command)
    {
        try
        {
            command.CorrelationId = Guid.NewGuid().ToString();
            var result = await _mediator.Send(command);

            if (result.Success)
            {
                return Ok(result);
            }

            return BadRequest(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing rollback transfer request");
            return StatusCode(500, new { error = "Internal server error" });
        }
    }

    [HttpGet("account/{accountId}")]
    public async Task<IActionResult> GetAccount(Guid accountId)
    {
        try
        {
            var query = new GetAccountQuery { AccountId = accountId };
            var result = await _mediator.Send(query);

            if (result == null)
            {
                return NotFound();
            }

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving account {AccountId}", accountId);
            return StatusCode(500, new { error = "Internal server error" });
        }
    }

    [HttpGet("transaction/{transactionId}")]
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

    [HttpGet("account/{accountId}/transactions")]
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

