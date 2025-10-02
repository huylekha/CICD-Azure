using MediatR;

namespace Shared.Domain.Queries;

public abstract class BaseQuery<TResponse> : IRequest<TResponse>
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
}

