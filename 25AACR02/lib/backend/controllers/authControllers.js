const User = require('../models/User');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
require('dotenv').config();
const { signupSchema, loginSchema } = require('../validators');

const JWT_SECRET = process.env.JWT_SECRET;

exports.signup = async (req, res) => {
    try {
        const parsed = signupSchema.safeParse(req.body);
        if (!parsed.success) {
            const errorMessages = parsed.error.errors.map(err => err.message);
            return res.status(400).json({ success: false, message: errorMessages.join(', ') });
        }

        const { 
            firstName, 
            lastName, 
            email, 
            password, 
            dateOfBirth, 
            gender, 
            location,
            education,
            currentlyWorking,
            profession,
            skillsRequired,
            skillsOffered,
            profileImage
        } = parsed.data;

        const userExists = await User.findOne({ email });
        if (userExists) {
            return res.status(400).json({ success: false, message: "User with this email already exists" });
        }

        const hashedPassword = await bcrypt.hash(password, 10);
        
        // Create full name
        const fullName = `${firstName} ${lastName}`;
        
        const newUser = new User({ 
            firstName,
            lastName,
            name: fullName,
            email, 
            password: hashedPassword,
            dateOfBirth: dateOfBirth || "",
            gender,
            location: location || "",
            education: education || "",
            currentlyWorking: currentlyWorking || "",
            profession: profession || "",
            skillsRequired: skillsRequired || [],
            skillsOffered: skillsOffered || [],
            skills: [...(skillsRequired || []), ...(skillsOffered || [])], // Combined for legacy compatibility
            profileImage: profileImage || ""
        });
        
        await newUser.save();

        res.status(201).json({ 
            success: true,
            message: "User created successfully",
            user: {
                id: newUser._id,
                firstName: newUser.firstName,
                lastName: newUser.lastName,
                name: newUser.name,
                email: newUser.email,
                gender: newUser.gender,
                location: newUser.location
            }
        });
    } catch (error) {
        console.error("Signup error:", error);
        res.status(500).json({ success: false, message: "Server error", error: error.message });
    }
};

exports.login = async (req, res) => {
    try {
        const parsed = loginSchema.safeParse(req.body);
        if (!parsed.success) {
            const errorMessages = parsed.error.errors.map(err => err.message);
            return res.status(400).json({ 
                success: false,
                message: errorMessages.join(', ') 
            });
        }

        const { email, password } = parsed.data;

        const userExists = await User.findOne({ email });
        if (!userExists) {
            return res.status(400).json({ 
                success: false,
                message: "User with this email does not exist" 
            });
        }

        const isMatch = await bcrypt.compare(password, userExists.password);
        if (!isMatch) {
            return res.status(400).json({ 
                success: false,
                message: "Invalid credentials" 
            });
        }

        const token = jwt.sign({ userId: userExists._id }, JWT_SECRET);
        res.json({
            success: true,
            message: "Login successful",
            data: {
                token,
                user: {
                    _id: userExists._id,
                    name: userExists.name,
                    email: userExists.email
                }
            }
        });
    } catch (error) {
        res.status(500).json({ 
            success: false,
            message: "Server error", 
            error: error.message 
        });
    }
};
