using Microsoft.AspNetCore.Mvc;

namespace PaymentService.Controllers;

/// <summary>
/// Demo Controller for testing API endpoints
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class DemoController : ControllerBase
{
    private readonly ILogger<DemoController> _logger;

    public DemoController(ILogger<DemoController> logger)
    {
        _logger = logger;
    }

    /// <summary>
    /// Get demo accounts
    /// </summary>
    /// <returns>List of demo accounts</returns>
    /// <response code="200">Returns the list of accounts</response>
    [HttpGet("accounts")]
    [ProducesResponseType(typeof(List<DemoAccount>), 200)]
    public IActionResult GetAccounts()
    {
        var accounts = new List<DemoAccount>
        {
            new DemoAccount { Id = Guid.NewGuid(), AccountNumber = "ACC001", AccountHolderName = "John Doe", Balance = 1000.00m, Currency = "USD" },
            new DemoAccount { Id = Guid.NewGuid(), AccountNumber = "ACC002", AccountHolderName = "Jane Smith", Balance = 2500.50m, Currency = "USD" },
            new DemoAccount { Id = Guid.NewGuid(), AccountNumber = "ACC003", AccountHolderName = "Bob Johnson", Balance = 750.25m, Currency = "USD" }
        };

        return Ok(accounts);
    }

    /// <summary>
    /// Get demo transactions
    /// </summary>
    /// <returns>List of demo transactions</returns>
    /// <response code="200">Returns the list of transactions</response>
    [HttpGet("transactions")]
    [ProducesResponseType(typeof(List<DemoTransaction>), 200)]
    public IActionResult GetTransactions()
    {
        var transactions = new List<DemoTransaction>
        {
            new DemoTransaction 
            { 
                Id = Guid.NewGuid(), 
                FromAccountId = Guid.NewGuid(), 
                ToAccountId = Guid.NewGuid(), 
                Amount = 100.00m, 
                Currency = "USD", 
                Status = "Completed", 
                CreatedAt = DateTime.UtcNow.AddHours(-1) 
            },
            new DemoTransaction 
            { 
                Id = Guid.NewGuid(), 
                FromAccountId = Guid.NewGuid(), 
                ToAccountId = Guid.NewGuid(), 
                Amount = 250.50m, 
                Currency = "USD", 
                Status = "Pending", 
                CreatedAt = DateTime.UtcNow.AddMinutes(-30) 
            }
        };

        return Ok(transactions);
    }

    /// <summary>
    /// Transfer money between accounts (Demo)
    /// </summary>
    /// <param name="request">Transfer request</param>
    /// <returns>Transfer result</returns>
    /// <response code="200">Transfer completed successfully</response>
    /// <response code="400">Invalid request</response>
    [HttpPost("transfer")]
    [ProducesResponseType(typeof(DemoTransferResult), 200)]
    [ProducesResponseType(400)]
    public IActionResult TransferMoney([FromBody] DemoTransferRequest request)
    {
        if (request.Amount <= 0)
        {
            return BadRequest(new DemoTransferResult { Success = false, ErrorMessage = "Amount must be greater than 0" });
        }

        if (request.FromAccountId == request.ToAccountId)
        {
            return BadRequest(new DemoTransferResult { Success = false, ErrorMessage = "Cannot transfer to the same account" });
        }

        // Simulate processing delay
        Thread.Sleep(1000);

        var result = new DemoTransferResult
        {
            Success = true,
            TransactionId = Guid.NewGuid(),
            Message = $"Successfully transferred {request.Amount:C} from {request.FromAccountId} to {request.ToAccountId}"
        };

        return Ok(result);
    }

    /// <summary>
    /// Get system health status
    /// </summary>
    /// <returns>Health status</returns>
    /// <response code="200">System is healthy</response>
    [HttpGet("health")]
    [ProducesResponseType(typeof(DemoHealthStatus), 200)]
    public IActionResult GetHealth()
    {
        var health = new DemoHealthStatus
        {
            Status = "Healthy",
            Timestamp = DateTime.UtcNow,
            Services = new Dictionary<string, string>
            {
                { "Database", "Connected" },
                { "RabbitMQ", "Connected" },
                { "PaymentService", "Running" }
            }
        };

        return Ok(health);
    }
}

// Demo Models
public class DemoAccount
{
    public Guid Id { get; set; }
    public string AccountNumber { get; set; } = string.Empty;
    public string AccountHolderName { get; set; } = string.Empty;
    public decimal Balance { get; set; }
    public string Currency { get; set; } = "USD";
}

public class DemoTransaction
{
    public Guid Id { get; set; }
    public Guid FromAccountId { get; set; }
    public Guid ToAccountId { get; set; }
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "USD";
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

public class DemoTransferRequest
{
    public Guid FromAccountId { get; set; }
    public Guid ToAccountId { get; set; }
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "USD";
    public string? Description { get; set; }
}

public class DemoTransferResult
{
    public bool Success { get; set; }
    public Guid? TransactionId { get; set; }
    public string? Message { get; set; }
    public string? ErrorMessage { get; set; }
}

public class DemoHealthStatus
{
    public string Status { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; }
    public Dictionary<string, string> Services { get; set; } = new();
}

