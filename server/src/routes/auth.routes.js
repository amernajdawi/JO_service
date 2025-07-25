const express = require('express');
const AuthController = require('../controllers/auth.controller');

const router = express.Router();

/**
 * @swagger
 * /auth/user/register:
 *   post:
 *     summary: Register a new user
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *               - fullName
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *                 description: User's email address
 *               password:
 *                 type: string
 *                 minLength: 6
 *                 description: User's password (minimum 6 characters)
 *               fullName:
 *                 type: string
 *                 description: User's full name
 *               phoneNumber:
 *                 type: string
 *                 description: User's phone number
 *               profilePictureUrl:
 *                 type: string
 *                 description: URL to user's profile picture
 *     responses:
 *       201:
 *         description: User registered successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                 user:
 *                   $ref: '#/components/schemas/User'
 *                 token:
 *                   type: string
 *       400:
 *         description: Validation error or user already exists
 *       500:
 *         description: Server error
 */
router.post('/user/register', AuthController.registerUser);

/**
 * @swagger
 * /auth/user/login:
 *   post:
 *     summary: User login
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *               password:
 *                 type: string
 *     responses:
 *       200:
 *         description: User logged in successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                 user:
 *                   $ref: '#/components/schemas/User'
 *                 token:
 *                   type: string
 *       401:
 *         description: Invalid credentials
 *       500:
 *         description: Server error
 */
router.post('/user/login', AuthController.loginUser);

/**
 * @swagger
 * /auth/provider/register:
 *   post:
 *     summary: Register a new service provider
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *               - fullName
 *               - serviceType
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *               password:
 *                 type: string
 *                 minLength: 6
 *               fullName:
 *                 type: string
 *               serviceType:
 *                 type: string
 *               hourlyRate:
 *                 type: number
 *               serviceDescription:
 *                 type: string
 *               locationLatitude:
 *                 type: number
 *               locationLongitude:
 *                 type: number
 *               addressText:
 *                 type: string
 *               city:
 *                 type: string
 *               availabilityDetails:
 *                 type: string
 *               profilePictureUrl:
 *                 type: string
 *     responses:
 *       201:
 *         description: Provider registered successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                 provider:
 *                   $ref: '#/components/schemas/Provider'
 *                 token:
 *                   type: string
 *       400:
 *         description: Validation error or provider already exists
 *       500:
 *         description: Server error
 */
router.post('/provider/register', AuthController.registerProvider);

/**
 * @swagger
 * /auth/provider/login:
 *   post:
 *     summary: Provider login
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *               password:
 *                 type: string
 *     responses:
 *       200:
 *         description: Provider logged in successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                 provider:
 *                   $ref: '#/components/schemas/Provider'
 *                 token:
 *                   type: string
 *       401:
 *         description: Invalid credentials
 *       500:
 *         description: Server error
 */
router.post('/provider/login', AuthController.loginProvider);

// Example of a protected route (can be moved to user.routes.js or provider.routes.js later)
// const { protectRoute, isUser } = require('../middlewares/auth.middleware');
// router.get('/user/profile', protectRoute, isUser, (req, res) => {
//     // Access req.auth.id (which is user_id) and req.auth.type ('user')
//     res.json({ message: 'This is a protected user profile route', user: req.auth });
// });

module.exports = router; 