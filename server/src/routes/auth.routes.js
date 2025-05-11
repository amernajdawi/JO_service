const express = require('express');
const AuthController = require('../controllers/auth.controller');

const router = express.Router();

// User Authentication Routes
router.post('/user/register', AuthController.registerUser);
router.post('/user/login', AuthController.loginUser);

// Provider Authentication Routes
router.post('/provider/register', AuthController.registerProvider);
router.post('/provider/login', AuthController.loginProvider);

// Example of a protected route (can be moved to user.routes.js or provider.routes.js later)
// const { protectRoute, isUser } = require('../middlewares/auth.middleware');
// router.get('/user/profile', protectRoute, isUser, (req, res) => {
//     // Access req.auth.id (which is user_id) and req.auth.type ('user')
//     res.json({ message: 'This is a protected user profile route', user: req.auth });
// });

module.exports = router; 