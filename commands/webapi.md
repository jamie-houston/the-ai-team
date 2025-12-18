# Create API Endpoints

Implement Web API controller(s) and DTOs based on the PRD.

## Your Task

1. Create request/response DTOs in Models/DTOs/ (use records)
2. Add validation attributes to request DTOs
3. Create controller in Controllers/
4. Implement CRUD endpoints (or as specified in PRD)
5. Use proper HTTP status codes (201, 204, 400, 404)
6. Verify `dotnet build` succeeds
7. Commit: "feat: add [Resource] API endpoints"

## If Authentication is Required

Add JWT authentication with these packages (use explicit versions for .NET 9):
```bash
dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer --version 9.0.0
dotnet add package BCrypt.Net-Next
```

Configure in Program.cs with **default values** that tests can match:
```csharp
// JWT Authentication - NOTE: Tests must use these same default values!
var jwtKey = builder.Configuration["Jwt:Key"] ?? "YourApp-Dev-Secret-Key-Min-32-Characters!";
var jwtIssuer = builder.Configuration["Jwt:Issuer"] ?? "YourApp";
var jwtAudience = builder.Configuration["Jwt:Audience"] ?? "YourApp";

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtIssuer,
            ValidAudience = jwtAudience,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey))
        };
    });
```

Create IJwtService that reads from the same IConfiguration - this ensures tokens are generated with matching values.

**Optional:** For production APIs, add versioning with `Asp.Versioning.Mvc` package (see webapi agent for details).

## IMPORTANT

After creating endpoints:
1. List the endpoints created (method, path, description)
2. Show the DTOs created
3. Confirm build succeeded
4. **STOP and wait for user review**
5. Tell user: "API endpoints complete. When ready, run `/test` to add tests"

Do NOT proceed to testing automatically.

## Focus (optional)

$ARGUMENTS

If no focus provided, implement all endpoints from PRD.md.
