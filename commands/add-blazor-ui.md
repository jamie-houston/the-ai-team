# Add Blazor UI to Existing API

Add a simple Blazor frontend to an existing Web API project.

## When to Use
- You finished the API early and have time remaining
- Interviewer asks for a UI
- Want to demonstrate full-stack C# skills

## Your Task

1. Add Blazor services to Program.cs:
   ```csharp
   builder.Services.AddRazorComponents()
       .AddInteractiveServerComponents();
   ```

2. Add Blazor middleware (after UseAuthorization, before MapControllers):
   ```csharp
   app.MapRazorComponents<App>()
       .AddInteractiveServerRenderMode();
   ```

3. Create Components folder structure:
   ```
   Components/
   ├── App.razor              # Root component
   ├── Routes.razor           # Router
   ├── Layout/
   │   └── MainLayout.razor   # Layout wrapper
   └── Pages/
       └── Home.razor         # Main page
   ```

4. Create a simple CRUD page that calls the API endpoints

5. Verify `dotnet build` succeeds

6. Verify the UI renders at the root URL

7. Commit: "feat: add Blazor UI for [Resource]"

## IMPORTANT

After adding UI:
1. Show the components created
2. Confirm the UI works
3. **STOP and wait for user review**

## Minimal App.razor
```razor
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <base href="/" />
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet" />
    <HeadOutlet />
</head>
<body>
    <Routes />
    <script src="_framework/blazor.web.js"></script>
</body>
</html>
```

## Note
This is a "nice to have" — only do this if API is complete and tested.
