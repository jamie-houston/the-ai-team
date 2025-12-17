# Load Data from File

Add data import functionality to seed the database from JSON or CSV files.

## When to Use
- Requirements include a dataset file (JSON, CSV)
- Need to seed database with initial data
- Data processing/transformation required

## Your Task

1. Identify the data file format (JSON or CSV)

2. Create a data seeding service:
   ```csharp
   public class DataSeeder
   {
       public static async Task SeedFromJsonAsync<T>(AppDbContext db, string filePath) where T : class
       {
           var json = await File.ReadAllTextAsync(filePath);
           var items = JsonSerializer.Deserialize<List<T>>(json);
           await db.Set<T>().AddRangeAsync(items);
           await db.SaveChangesAsync();
       }
   }
   ```

3. For CSV, add CsvHelper package:
   ```bash
   dotnet add package CsvHelper
   ```

4. Add seed endpoint or startup seeding in Program.cs

5. Verify data loads correctly

6. Commit: "feat: add data seeding from [format]"

## Common Patterns

### JSON Loading
```csharp
var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
var data = JsonSerializer.Deserialize<List<MyModel>>(json, options);
```

### CSV Loading
```csharp
using var reader = new StreamReader(filePath);
using var csv = new CsvReader(reader, CultureInfo.InvariantCulture);
var records = csv.GetRecords<MyModel>().ToList();
```

### Startup Seeding
```csharp
// In Program.cs after EnsureCreated()
if (!db.Items.Any())
{
    await DataSeeder.SeedFromJsonAsync<Item>(db, "Data/seed.json");
}
```

## IMPORTANT

After adding data loading:
1. Show what was loaded (count, sample)
2. Verify API returns the data
3. **STOP and wait for user review**
