-- Add approval-related columns to profiles table
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS is_approved BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS approval_date TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS approval_rejected BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

-- Create leave_types table for custom leave types
CREATE TABLE IF NOT EXISTS public.leave_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(name, created_by)
);

-- Enable RLS on leave_types
ALTER TABLE public.leave_types ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for leave_types
DROP POLICY IF EXISTS "Everyone can view leave types" ON public.leave_types;
DROP POLICY IF EXISTS "Admins can manage leave types" ON public.leave_types;
CREATE POLICY "Everyone can view leave types" ON public.leave_types FOR SELECT USING (true);
CREATE POLICY "Admins can manage leave types" ON public.leave_types FOR ALL USING (public.has_role(auth.uid(), 'admin'));

-- Create index for leave_types
CREATE INDEX IF NOT EXISTS idx_leave_types_created_by ON public.leave_types(created_by);

-- Create trigger for leave_types updated_at
DROP TRIGGER IF EXISTS update_leave_types_updated_at ON public.leave_types;
CREATE TRIGGER update_leave_types_updated_at BEFORE UPDATE ON public.leave_types FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Add support for custom leave types in leave_requests table
ALTER TABLE public.leave_requests
ADD COLUMN IF NOT EXISTS custom_type_id UUID REFERENCES public.leave_types(id) ON DELETE SET NULL;
