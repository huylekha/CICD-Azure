using MediatR;
using Microsoft.AspNetCore.Mvc;
using PaymentService.Services;
using Shared.Domain.Queries;

namespace PaymentService.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AccountController : ControllerBase
{
    private readonly IMediator _mediator;
    private readonly IAccountService _accountService;
    private readonly ILogger<AccountController> _logger;

    public AccountController(IMediator mediator, IAccountService accountService, ILogger<AccountController> logger)
    {
        _mediator = mediator;
        _accountService = accountService;
        _logger = logger;
    }

    [HttpGet("{accountId}")]
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

    [HttpGet]
    public async Task<IActionResult> GetAllAccounts()
    {
        try
        {
            // Mock data for demo - in real app, this would be a proper query
            var accounts = new[]
            {
                new GetAccountResult
                {
                    Id = Guid.Parse("550e8400-e29b-41d4-a716-446655440001"),
                    AccountNumber = "ACC001",
                    AccountHolderName = "John Doe",
                    Balance = 5000,
                    Currency = "USD",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow.AddDays(-30),
                    UpdatedAt = DateTime.UtcNow
                },
                new GetAccountResult
                {
                    Id = Guid.Parse("550e8400-e29b-41d4-a716-446655440002"),
                    AccountNumber = "ACC002",
                    AccountHolderName = "Jane Smith",
                    Balance = 3000,
                    Currency = "USD",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow.AddDays(-25),
                    UpdatedAt = DateTime.UtcNow
                },
                new GetAccountResult
                {
                    Id = Guid.Parse("550e8400-e29b-41d4-a716-446655440003"),
                    AccountNumber = "ACC003",
                    AccountHolderName = "Bob Johnson",
                    Balance = 7500,
                    Currency = "USD",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow.AddDays(-20),
                    UpdatedAt = DateTime.UtcNow
                },
                new GetAccountResult
                {
                    Id = Guid.Parse("550e8400-e29b-41d4-a716-446655440004"),
                    AccountNumber = "ACC004",
                    AccountHolderName = "Alice Brown",
                    Balance = 1200,
                    Currency = "USD",
                    IsActive = false,
                    CreatedAt = DateTime.UtcNow.AddDays(-15),
                    UpdatedAt = DateTime.UtcNow
                },
                new GetAccountResult
                {
                    Id = Guid.Parse("550e8400-e29b-41d4-a716-446655440005"),
                    AccountNumber = "ACC005",
                    AccountHolderName = "Charlie Wilson",
                    Balance = 9800,
                    Currency = "USD",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow.AddDays(-10),
                    UpdatedAt = DateTime.UtcNow
                }
            };

            return Ok(accounts);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving accounts");
            return StatusCode(500, new { error = "Internal server error" });
        }
    }

    [HttpPost]
    public async Task<IActionResult> CreateAccount([FromBody] CreateAccountRequest request)
    {
        try
        {
            var account = await _accountService.CreateAccountAsync(
                request.AccountNumber,
                request.AccountHolderName,
                request.InitialBalance,
                request.Currency
            );

            return CreatedAtAction(nameof(GetAccount), new { accountId = account.Id }, account);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating account");
            return StatusCode(500, new { error = "Internal server error" });
        }
    }
}

public class CreateAccountRequest
{
    public string AccountNumber { get; set; } = string.Empty;
    public string AccountHolderName { get; set; } = string.Empty;
    public decimal InitialBalance { get; set; }
    public string Currency { get; set; } = "USD";
}
