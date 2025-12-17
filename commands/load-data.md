# Load Data from File

Add data import functionality to seed the database from JSON or CSV files.

## When to Use
- Requirements include a dataset file (JSON, CSV)
- Need to seed database with initial data
- Data processing/transformation required

## Your Task

1. Identify the data file format (JSON or CSV)

2. **Copy the data file into the project** (e.g., `src/ProjectName.Api/Data/seed-data.json`)
   - Don't use fragile relative paths like `../../..` to find files outside the project

3. Create a data seeding service in `Data/DataSeeder.cs`:
   ```csharp
   using System.Text.Json;
   using System.Text.Json.Serialization;
   using Microsoft.EntityFrameworkCore;  // Don't forget this!
   using YourProject.Api.Models;

   public static class DataSeeder
   {
       public static async Task SeedFromJsonAsync(AppDbContext db, string filePath)
       {
           // Check if already seeded (including soft-deleted items)
           if (await db.YourEntity.IgnoreQueryFilters().AnyAsync())
               return;

           var json = await File.ReadAllTextAsync(filePath);
           var options = new JsonSerializerOptions
           {
               PropertyNameCaseInsensitive = true,
               Converters = { new JsonStringEnumConverter() }
           };
           var items = JsonSerializer.Deserialize<List<YourEntity>>(json, options);
           // ... add to db
       }
   }
   ```

4. **Handle enum string mapping**: If JSON has strings like "Office Supplies" but enum is `OfficeSupplies`:
   ```csharp
   // Create a seed DTO with string Category, then map manually:
   private static Category ParseCategory(string category)
   {
       var normalized = category.Replace(" ", "");
       return Enum.Parse<Category>(normalized, ignoreCase: true);
   }
   ```

5. For CSV, add CsvHelper package:
   ```bash
   dotnet add package CsvHelper
   ```

6. Add startup seeding in Program.cs:
   ```csharp
   // In Program.cs after EnsureCreated()
   var seedPath = Path.Combine(app.Environment.ContentRootPath, "Data", "seed-data.json");
   if (File.Exists(seedPath))
   {
       await DataSeeder.SeedFromJsonAsync(db, seedPath);
   }
   ```

7. Verify data loads correctly

8. Commit: "feat: add data seeding from [format]"

## IMPORTANT

After adding data loading:
1. Show what was loaded (count, sample)
2. Verify API returns the data
3. **STOP and wait for user review**
