const { z } = require('zod');

const signupSchema = z.object({
    firstName: z.string().min(1, 'First name is required'),
    lastName: z.string().min(1, 'Last name is required'),
    email: z.string().email('Invalid email format'),
    password: z.string().min(6, 'Password must be at least 6 characters'),
    dateOfBirth: z.string().optional(),
    gender: z.string().min(1, 'Gender is required'),
    location: z.string().optional(),
    education: z.string().optional(),
    currentlyWorking: z.string().optional(),
    profession: z.string().optional(),
    skillsRequired: z.array(z.string()).optional(),
    skillsOffered: z.array(z.string()).optional(),
    profileImage: z.string().optional(),
});

const loginSchema = z.object({
    email: z.string().email('Invalid email format'),
    password: z.string().min(1, 'Password is required'),
});

const profileUpdateSchema = z.object({
    name: z.string().min(1, 'Name cannot be empty').optional(),
    email: z.string().email('Invalid email format').optional(),
    phone: z.string().optional(),
    bio: z.string().optional(),
    location: z.string().optional(),
    dateOfBirth: z.string().optional(),
    skills: z.array(z.string()).optional(),
    education: z.string().optional(),
    profession: z.string().optional(),
    currentlyWorking: z.string().optional(),
    skillsRequired: z.array(z.string()).optional(),
    skillsOffered: z.array(z.string()).optional(),
    profileImage: z.string().optional(),
});

module.exports = {
    signupSchema,
    loginSchema,
    profileUpdateSchema,
};
