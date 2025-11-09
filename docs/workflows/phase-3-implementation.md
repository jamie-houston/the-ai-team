# Phase 3: Implementation

## Overview

**Duration**: 2-week sprints (repeatable)
**Objective**: Build features according to sprint plan
**Approval Gate**: None (continuous delivery with quality gates)
**Prerequisites**: Phase 2 architecture and sprint plan approved

This is the core development phase where features are built, tested, and refined in iterative sprints.

---

## Sprint Structure

### 2-Week Sprint Timeline

```
Week 1:
  Day 1-2:  Sprint Planning & Setup
  Day 3-5:  Core Implementation (Backend + Frontend in parallel)

Week 2:
  Day 6-8:  Feature Completion & Integration
  Day 9-10: Testing & Code Review
  Day 11-12: Documentation & Sprint Review
  Day 13-14: Sprint Retrospective & Next Sprint Prep
```

---

## Implementation Agents

### Backend Development Stream

#### 1. Framework-Specific Backend Experts

**Available Agents:**
- `django-backend-expert` (✅ EXISTING)
- `laravel-backend-expert` (✅ EXISTING)
- `rails-backend-expert` (✅ EXISTING)
- `backend-developer` (✅ EXISTING - Universal fallback)

**Role**: Implement business logic, controllers, and service layers

**Responsibilities:**
- Implement controllers/views
- Business logic and service layers
- Input validation
- Error handling
- Dependency injection
- Background job setup

**Input:**
- API specification (from api-architect)
- Database schema (from database-architect)
- Sprint backlog stories

**Output Example (Django):**
```python
# users/views.py
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import User
from .serializers import UserSerializer

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_users(request):
    """
    List all users with pagination and filtering.

    Query params:
    - page: Page number (default: 1)
    - page_size: Items per page (default: 20)
    - search: Filter by email or name
    - role: Filter by role name
    """
    page = int(request.GET.get('page', 1))
    page_size = min(int(request.GET.get('page_size', 20)), 100)

    users = User.objects.filter(is_active=True)

    # Apply filters
    if search := request.GET.get('search'):
        users = users.filter(
            Q(email__icontains=search) |
            Q(profile__first_name__icontains=search)
        )

    if role := request.GET.get('role'):
        users = users.filter(roles__name=role)

    # Pagination
    total_count = users.count()
    start = (page - 1) * page_size
    end = start + page_size
    users_page = users[start:end]

    serializer = UserSerializer(users_page, many=True)

    return Response({
        'data': serializer.data,
        'pagination': {
            'page': page,
            'page_size': page_size,
            'total_pages': (total_count + page_size - 1) // page_size,
            'total_count': total_count
        }
    })
```

---

#### 2. Framework-Specific ORM Experts

**Available Agents:**
- `django-orm-expert` (✅ EXISTING)
- `laravel-eloquent-expert` (✅ EXISTING)
- `rails-activerecord-expert` (✅ EXISTING)

**Role**: Implement data models and database operations

**Responsibilities:**
- Create model definitions
- Write database migrations
- Implement model methods and properties
- Query optimization
- Seed data creation

**Output Example (Django):**
```python
# users/models.py
from django.db import models
from django.contrib.auth.models import AbstractBaseUser
import uuid

class User(AbstractBaseUser):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True, max_length=255)
    email_verified = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    last_login = models.DateTimeField(null=True, blank=True)
    is_active = models.BooleanField(default=True)

    USERNAME_FIELD = 'email'

    class Meta:
        db_table = 'users'
        indexes = [
            models.Index(fields=['email']),
            models.Index(fields=['-created_at']),
        ]

    def __str__(self):
        return self.email

    @property
    def full_name(self):
        if hasattr(self, 'profile'):
            return f"{self.profile.first_name} {self.profile.last_name}"
        return self.email

    def has_permission(self, permission_name):
        """Check if user has a specific permission through roles."""
        return self.roles.filter(
            permissions__name=permission_name
        ).exists()

class Role(models.Model):
    name = models.CharField(max_length=50, unique=True)
    description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'roles'

    def __str__(self):
        return self.name

class UserRole(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='user_roles')
    role = models.ForeignKey(Role, on_delete=models.CASCADE, related_name='user_roles')
    assigned_at = models.DateTimeField(auto_now_add=True)
    assigned_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='role_assignments')

    class Meta:
        db_table = 'user_roles'
        unique_together = ('user', 'role')
```

**Migration Example:**
```python
# migrations/0001_initial.py
from django.db import migrations, models

class Migration(migrations.Migration):
    initial = True

    operations = [
        migrations.CreateModel(
            name='User',
            fields=[
                ('id', models.UUIDField(primary_key=True, default=uuid.uuid4)),
                ('email', models.EmailField(unique=True, max_length=255)),
                ('password', models.CharField(max_length=255)),
                ('email_verified', models.BooleanField(default=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('is_active', models.BooleanField(default=True)),
            ],
        ),
        migrations.AddIndex(
            model_name='user',
            index=models.Index(fields=['email'], name='users_email_idx'),
        ),
    ]
```

---

#### 3. API Developers

**Available Agents:**
- `django-api-developer` (✅ EXISTING)
- `rails-api-developer` (✅ EXISTING)
- `api-architect` (✅ EXISTING - Universal fallback)

**Role**: Implement REST/GraphQL API endpoints

**Responsibilities:**
- Implement API endpoints per OpenAPI spec
- Request/response serialization
- Input validation
- Error handling with proper HTTP status codes
- API versioning
- Rate limiting integration

**Output Example (Django REST Framework):**
```python
# users/serializers.py
from rest_framework import serializers
from .models import User, Role

class RoleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Role
        fields = ['id', 'name', 'description']

class UserSerializer(serializers.ModelSerializer):
    roles = RoleSerializer(many=True, read_only=True)
    full_name = serializers.ReadOnlyField()

    class Meta:
        model = User
        fields = ['id', 'email', 'email_verified', 'full_name',
                  'roles', 'is_active', 'created_at', 'last_login']
        read_only_fields = ['id', 'created_at', 'email_verified']

class UserCreateSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(min_length=8, write_only=True)
    password_confirm = serializers.CharField(write_only=True)

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("Email already exists")
        return value.lower()

    def validate(self, data):
        if data['password'] != data['password_confirm']:
            raise serializers.ValidationError({
                "password_confirm": "Passwords do not match"
            })
        return data

    def create(self, validated_data):
        validated_data.pop('password_confirm')
        user = User.objects.create_user(**validated_data)
        return user
```

---

### Frontend Development Stream

#### 4. Framework-Specific Frontend Experts

**Available Agents:**
- `react-component-architect` (✅ EXISTING)
- `vue-component-architect` (✅ EXISTING)
- `react-nextjs-expert` (✅ EXISTING)
- `vue-nuxt-expert` (✅ EXISTING)
- `vue-state-manager` (✅ EXISTING)
- `frontend-developer` (✅ EXISTING - Universal fallback)

**Role**: Build UI components and implement frontend logic

**Responsibilities:**
- Build reusable components
- State management (Redux, Pinia, etc.)
- Routing configuration
- Form handling and validation
- API integration
- Error boundary implementation

**Output Example (React + TypeScript):**
```tsx
// src/components/auth/LoginForm.tsx
import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/hooks/useAuth';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { toast } from '@/utils/toast';

interface LoginFormData {
  email: string;
  password: string;
}

interface FormErrors {
  email?: string;
  password?: string;
}

export const LoginForm: React.FC = () => {
  const [formData, setFormData] = useState<LoginFormData>({
    email: '',
    password: ''
  });
  const [errors, setErrors] = useState<FormErrors>({});
  const [isLoading, setIsLoading] = useState(false);

  const { login } = useAuth();
  const navigate = useNavigate();

  const validateForm = (): boolean => {
    const newErrors: FormErrors = {};

    if (!formData.email) {
      newErrors.email = 'Email is required';
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
      newErrors.email = 'Invalid email format';
    }

    if (!formData.password) {
      newErrors.password = 'Password is required';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!validateForm()) return;

    setIsLoading(true);

    try {
      await login(formData.email, formData.password);
      toast.success('Login successful!');
      navigate('/dashboard');
    } catch (error: any) {
      if (error.response?.status === 401) {
        toast.error('Invalid email or password');
      } else if (error.response?.status === 403) {
        toast.error('Account not verified or disabled');
      } else {
        toast.error('Login failed. Please try again.');
      }
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4 w-full max-w-md">
      <Input
        type="email"
        label="Email"
        value={formData.email}
        onChange={(e) => setFormData({ ...formData, email: e.target.value })}
        error={errors.email}
        disabled={isLoading}
        autoComplete="email"
      />

      <Input
        type="password"
        label="Password"
        value={formData.password}
        onChange={(e) => setFormData({ ...formData, password: e.target.value })}
        error={errors.password}
        disabled={isLoading}
        autoComplete="current-password"
      />

      <div className="flex items-center justify-between">
        <a href="/forgot-password" className="text-sm text-blue-600 hover:underline">
          Forgot password?
        </a>
      </div>

      <Button
        type="submit"
        fullWidth
        isLoading={isLoading}
        disabled={isLoading}
      >
        {isLoading ? 'Logging in...' : 'Log In'}
      </Button>
    </form>
  );
};
```

---

#### 5. tailwind-css-expert

**Status**: ✅ EXISTING
**Role**: Styling and responsive design

**Responsibilities:**
- Implement Tailwind utility classes
- Create custom theme configuration
- Responsive design patterns
- Dark mode support
- Component styling
- Accessibility styling (focus states, ARIA)

**Output Example:**
```tsx
// src/components/ui/Button.tsx
import React from 'react';
import { clsx } from 'clsx';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  fullWidth?: boolean;
  isLoading?: boolean;
}

export const Button: React.FC<ButtonProps> = ({
  variant = 'primary',
  size = 'md',
  fullWidth = false,
  isLoading = false,
  children,
  className,
  disabled,
  ...props
}) => {
  return (
    <button
      className={clsx(
        // Base styles
        'inline-flex items-center justify-center font-medium rounded-lg transition-colors',
        'focus:outline-none focus:ring-2 focus:ring-offset-2',
        'disabled:opacity-50 disabled:cursor-not-allowed',

        // Variant styles
        {
          'bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500': variant === 'primary',
          'bg-gray-200 text-gray-900 hover:bg-gray-300 focus:ring-gray-500': variant === 'secondary',
          'bg-red-600 text-white hover:bg-red-700 focus:ring-red-500': variant === 'danger',
        },

        // Size styles
        {
          'px-3 py-1.5 text-sm': size === 'sm',
          'px-4 py-2 text-base': size === 'md',
          'px-6 py-3 text-lg': size === 'lg',
        },

        // Width
        {
          'w-full': fullWidth,
        },

        className
      )}
      disabled={disabled || isLoading}
      {...props}
    >
      {isLoading && (
        <svg className="animate-spin -ml-1 mr-2 h-4 w-4" fill="none" viewBox="0 0 24 24">
          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
        </svg>
      )}
      {children}
    </button>
  );
};
```

---

### Cross-Cutting Agents

#### 6. security-expert

**Status**: ✅ EXISTING (Python-focused, needs expansion)
**Role**: Security implementation and review

**Responsibilities:**
- Authentication/authorization implementation
- Input sanitization and validation
- CSRF/XSS prevention
- SQL injection prevention
- Secure password handling (bcrypt, argon2)
- API security (JWT, rate limiting)
- OWASP Top 10 compliance
- Security headers configuration

**Security Checklist:**
```
[ ] Passwords hashed with bcrypt/argon2 (min 8 characters)
[ ] JWT tokens properly signed and validated
[ ] CSRF protection enabled for state-changing operations
[ ] XSS prevention (input sanitization, CSP headers)
[ ] SQL injection prevented (parameterized queries/ORM)
[ ] Rate limiting on auth endpoints (5 attempts/minute)
[ ] HTTPS enforced in production
[ ] Security headers set (X-Frame-Options, X-Content-Type-Options, etc.)
[ ] Sensitive data not logged
[ ] API keys/secrets in environment variables
```

---

#### 7. integration-engineer

**Status**: 🔴 NEW - Priority: MEDIUM
**Role**: Third-party integrations and API clients

**Responsibilities:**
- Implement external API clients
- Webhook handlers
- OAuth flows (Google, GitHub, etc.)
- Payment gateway integrations (Stripe, PayPal)
- Email service integration (SendGrid, Mailgun)
- SMS service integration (Twilio)
- Cloud storage integration (S3, GCS)

**Output Example (OAuth Integration):**
```python
# auth/oauth/google.py
import requests
from django.conf import settings
from django.shortcuts import redirect
from rest_framework.decorators import api_view
from rest_framework.response import Response

GOOGLE_OAUTH_URL = 'https://accounts.google.com/o/oauth2/v2/auth'
GOOGLE_TOKEN_URL = 'https://oauth2.googleapis.com/token'
GOOGLE_USERINFO_URL = 'https://www.googleapis.com/oauth2/v2/userinfo'

@api_view(['GET'])
def google_login(request):
    """Redirect to Google OAuth consent screen."""
    params = {
        'client_id': settings.GOOGLE_CLIENT_ID,
        'redirect_uri': settings.GOOGLE_REDIRECT_URI,
        'response_type': 'code',
        'scope': 'openid email profile',
        'access_type': 'offline',
        'prompt': 'consent'
    }

    url = f"{GOOGLE_OAUTH_URL}?{'&'.join(f'{k}={v}' for k, v in params.items())}"
    return redirect(url)

@api_view(['GET'])
def google_callback(request):
    """Handle OAuth callback and create/login user."""
    code = request.GET.get('code')

    if not code:
        return Response({'error': 'No authorization code'}, status=400)

    # Exchange code for tokens
    token_data = {
        'code': code,
        'client_id': settings.GOOGLE_CLIENT_ID,
        'client_secret': settings.GOOGLE_CLIENT_SECRET,
        'redirect_uri': settings.GOOGLE_REDIRECT_URI,
        'grant_type': 'authorization_code'
    }

    token_response = requests.post(GOOGLE_TOKEN_URL, data=token_data)
    tokens = token_response.json()

    # Get user info
    headers = {'Authorization': f"Bearer {tokens['access_token']}"}
    userinfo_response = requests.get(GOOGLE_USERINFO_URL, headers=headers)
    userinfo = userinfo_response.json()

    # Create or get user
    user, created = User.objects.get_or_create(
        email=userinfo['email'],
        defaults={
            'email_verified': True,
            'oauth_provider': 'google',
            'oauth_id': userinfo['id']
        }
    )

    # Generate JWT tokens
    from rest_framework_simplejwt.tokens import RefreshToken
    refresh = RefreshToken.for_user(user)

    return Response({
        'access_token': str(refresh.access_token),
        'refresh_token': str(refresh),
        'user': UserSerializer(user).data
    })
```

---

### Quality Assurance Agents

#### 8. testing-expert

**Status**: ✅ EXISTING (Python-focused, needs expansion)
**Role**: Test development and coverage

**Responsibilities:**
- Write unit tests (80%+ coverage target)
- Integration tests
- End-to-end tests
- Test data factories and fixtures
- Mock/stub creation
- Test coverage analysis

**Output Example (Django Tests):**
```python
# users/tests/test_views.py
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from users.models import User, Role

class UserListAPITest(TestCase):
    def setUp(self):
        self.client = APIClient()

        # Create test user and authenticate
        self.user = User.objects.create_user(
            email='test@example.com',
            password='testpass123'
        )
        self.client.force_authenticate(user=self.user)

        # Create additional users
        User.objects.create_user(email='user1@example.com', password='pass123')
        User.objects.create_user(email='user2@example.com', password='pass123')

    def test_list_users_authenticated(self):
        """Test that authenticated user can list users."""
        response = self.client.get('/api/v1/users/')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['data']), 3)
        self.assertIn('pagination', response.data)

    def test_list_users_pagination(self):
        """Test pagination works correctly."""
        response = self.client.get('/api/v1/users/?page=1&page_size=2')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['data']), 2)
        self.assertEqual(response.data['pagination']['total_count'], 3)
        self.assertEqual(response.data['pagination']['total_pages'], 2)

    def test_list_users_search_filter(self):
        """Test search filtering by email."""
        response = self.client.get('/api/v1/users/?search=user1')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['data']), 1)
        self.assertEqual(response.data['data'][0]['email'], 'user1@example.com')

    def test_list_users_unauthenticated(self):
        """Test that unauthenticated request is rejected."""
        self.client.force_authenticate(user=None)
        response = self.client.get('/api/v1/users/')

        self.assertEqual(response.status.HTTP_401_UNAUTHORIZED)
```

**Frontend Test Example (React + Jest):**
```tsx
// src/components/auth/LoginForm.test.tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { LoginForm } from './LoginForm';
import { useAuth } from '@/hooks/useAuth';

jest.mock('@/hooks/useAuth');
jest.mock('react-router-dom', () => ({
  useNavigate: () => jest.fn()
}));

describe('LoginForm', () => {
  const mockLogin = jest.fn();

  beforeEach(() => {
    (useAuth as jest.Mock).mockReturnValue({
      login: mockLogin
    });
  });

  it('renders email and password inputs', () => {
    render(<LoginForm />);

    expect(screen.getByLabelText(/email/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/password/i)).toBeInTheDocument();
  });

  it('shows validation errors for empty fields', async () => {
    render(<LoginForm />);

    fireEvent.click(screen.getByRole('button', { name: /log in/i }));

    await waitFor(() => {
      expect(screen.getByText(/email is required/i)).toBeInTheDocument();
      expect(screen.getByText(/password is required/i)).toBeInTheDocument();
    });
  });

  it('submits form with valid data', async () => {
    mockLogin.mockResolvedValueOnce({});

    render(<LoginForm />);

    fireEvent.change(screen.getByLabelText(/email/i), {
      target: { value: 'test@example.com' }
    });
    fireEvent.change(screen.getByLabelText(/password/i), {
      target: { value: 'password123' }
    });

    fireEvent.click(screen.getByRole('button', { name: /log in/i }));

    await waitFor(() => {
      expect(mockLogin).toHaveBeenCalledWith('test@example.com', 'password123');
    });
  });
});
```

---

#### 9. code-reviewer

**Status**: ✅ EXISTING
**Role**: Code quality and security review

**Responsibilities:**
- Security code review
- Best practices enforcement
- Code style consistency
- Identify code smells
- Suggest refactoring opportunities
- Check for performance anti-patterns

**Review Report Format:**
```
## Code Review Report

### Critical Issues (Must Fix)
1. **SQL Injection Risk** - users/views.py:45
   - Using string formatting for SQL query
   - Fix: Use parameterized queries or ORM

2. **Hardcoded Secret** - config/settings.py:12
   - JWT secret key hardcoded
   - Fix: Move to environment variable

### High Priority
3. **Missing Input Validation** - auth/views.py:78
   - Email not validated before use
   - Fix: Add email format validation

4. **Error Leaking Information** - api/errors.py:23
   - Stack traces exposed in production
   - Fix: Return generic error messages

### Medium Priority
5. **Missing Test Coverage** - users/services.py
   - UserService.create_user() has no tests
   - Fix: Add unit tests

6. **Code Duplication** - auth/views.py:45-67, users/views.py:89-111
   - Duplicate authentication logic
   - Fix: Extract to shared decorator/middleware

### Low Priority (Code Style)
7. **Inconsistent Naming** - users/models.py
   - Mix of snake_case and camelCase
   - Fix: Use snake_case consistently

### Positive Findings
- ✅ Good separation of concerns
- ✅ Proper error handling in most places
- ✅ Clear docstrings

### Recommendations
- Consider implementing a UserRepository pattern
- Add logging for authentication failures
- Implement request ID tracking for debugging
```

---

#### 10. performance-optimizer

**Status**: ✅ EXISTING
**Role**: Performance analysis and optimization

**Responsibilities:**
- Identify bottlenecks
- Query optimization (N+1 queries, missing indexes)
- Caching strategies
- Load testing
- Profiling
- Scalability assessment

**Performance Report:**
```
## Performance Analysis Report

### Slow Endpoints (> 200ms)

1. **GET /api/v1/users** - 847ms average
   - **Issue**: N+1 query problem loading roles
   - **Fix**: Use select_related('roles')
   - **Impact**: Reduces to ~45ms (95% improvement)

2. **GET /api/v1/users/:id** - 523ms average
   - **Issue**: Missing index on user_roles.user_id
   - **Fix**: Add database index
   - **Impact**: Reduces to ~78ms (85% improvement)

### Query Optimization

**Before:**
```python
users = User.objects.all()
for user in users:
    roles = user.roles.all()  # N+1 query!
```

**After:**
```python
users = User.objects.prefetch_related('roles').all()
```

### Caching Recommendations

1. **User Permissions** (Currently DB query every request)
   - Cache in Redis with 5-minute TTL
   - Invalidate on role assignment change
   - Expected impact: 70% reduction in DB load

2. **User List** (Frequently accessed)
   - Cache first page for 1 minute
   - Cache per-user customized views separately
   - Expected impact: 50% faster response

### Load Test Results

**Test**: 1000 concurrent users, 60 seconds
- **Total Requests**: 45,230
- **Success Rate**: 99.8%
- **Average Response Time**: 124ms
- **95th Percentile**: 287ms
- **Errors**: 89 (mostly timeouts on /users endpoint)

**Recommendations:**
- Add connection pooling (currently single connection)
- Implement rate limiting (prevent abuse)
- Consider horizontal scaling at 10K users
```

---

#### 11. documentation-specialist

**Status**: ✅ EXISTING
**Role**: Technical documentation

**Responsibilities:**
- API documentation (OpenAPI/Swagger)
- Code comments and docstrings
- README updates
- Architecture diagrams
- Deployment guides
- User guides

**Output Examples:**

```python
# Well-documented code
def assign_role_to_user(user_id: str, role_id: int, assigned_by_id: str) -> UserRole:
    """
    Assign a role to a user with audit logging.

    Args:
        user_id: UUID of the user to assign role to
        role_id: ID of the role to assign
        assigned_by_id: UUID of the user performing the assignment (for audit)

    Returns:
        UserRole: The created user-role association

    Raises:
        User.DoesNotExist: If user_id or assigned_by_id is invalid
        Role.DoesNotExist: If role_id is invalid
        PermissionError: If assigned_by does not have 'users.manage_roles' permission
        IntegrityError: If user already has this role

    Example:
        >>> user_role = assign_role_to_user(
        ...     user_id="550e8400-e29b-41d4-a716-446655440000",
        ...     role_id=2,
        ...     assigned_by_id="admin-uuid"
        ... )
        >>> user_role.role.name
        'editor'
    """
    user = User.objects.get(id=user_id)
    role = Role.objects.get(id=role_id)
    assigned_by = User.objects.get(id=assigned_by_id)

    # Permission check
    if not assigned_by.has_permission('users.manage_roles'):
        raise PermissionError("Insufficient permissions to assign roles")

    # Create assignment
    user_role = UserRole.objects.create(
        user=user,
        role=role,
        assigned_by=assigned_by
    )

    logger.info(f"Role '{role.name}' assigned to user {user.email} by {assigned_by.email}")

    return user_role
```

---

## Phase 3 Workflow

### Sprint Execution Flow

```
Day 1-2: Sprint Setup
├─ Sprint planning meeting (review backlog)
├─ Create feature branches
├─ Set up development environments
└─ Assign tasks to agents

Days 3-8: Implementation (Parallel Streams)
├─ Backend Stream:
│  ├─ database-architect: Run migrations
│  ├─ django-orm-expert: Implement models
│  ├─ django-backend-expert: Business logic
│  └─ django-api-developer: API endpoints
│
├─ Frontend Stream:
│  ├─ react-component-architect: Build components
│  └─ tailwind-css-expert: Style components
│
└─ Cross-cutting:
   ├─ security-expert: Review auth code
   └─ integration-engineer: OAuth setup

Days 9-10: Quality Assurance
├─ testing-expert: Write tests
├─ code-reviewer: Review all code
└─ performance-optimizer: Identify bottlenecks

Days 11-12: Documentation & Refinement
├─ documentation-specialist: Update docs
├─ Fix review findings
└─ Sprint review with user

Days 13-14: Retrospective & Planning
├─ Sprint retrospective (what went well/poorly)
├─ Update velocity metrics
└─ Plan next sprint
```

---

## Deliverables Checklist

For each sprint:

- [ ] **Working Software**
  - [ ] All user stories completed
  - [ ] Acceptance criteria met
  - [ ] Potentially shippable increment

- [ ] **Tests**
  - [ ] Unit tests (80%+ coverage)
  - [ ] Integration tests pass
  - [ ] E2E tests for critical flows

- [ ] **Code Quality**
  - [ ] Code review completed
  - [ ] No critical or high-priority issues
  - [ ] Security review passed

- [ ] **Performance**
  - [ ] No endpoints slower than 200ms
  - [ ] Query optimization completed
  - [ ] Caching implemented where needed

- [ ] **Documentation**
  - [ ] API docs updated (OpenAPI)
  - [ ] Code comments added
  - [ ] README updated if needed

---

## Common Pitfalls

### 1. Scope Creep
**Problem**: Adding features mid-sprint
**Solution**: Strict sprint boundaries, new features go to backlog

### 2. Skipping Tests
**Problem**: "We'll add tests later"
**Solution**: Tests are part of definition of done

### 3. Integration at End
**Problem**: Backend and frontend integrate on day 10
**Solution**: Continuous integration, API contracts defined upfront

### 4. No Code Review
**Problem**: Merging without review
**Solution**: code-reviewer must approve before merge

---

## Next Phase

After sprint(s) complete, proceed to [Phase 4: Integration & Testing](./phase-4-integration.md)