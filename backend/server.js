const express = require('express');
const { Pool } = require('pg');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

// ==========================================
// 🔌 CRASH-PROOF DATABASE CONFIGURATION
// ==========================================
const dbConfig = {
    connectionString: process.env.DATABASE_URL,
    connectionTimeoutMillis: 10000, 
    max: 20 // Enforce an explicit pool connection cap ceiling for safety
};

if (process.env.DATABASE_URL && !process.env.DATABASE_URL.includes('localhost')) {
    dbConfig.ssl = {
        rejectUnauthorized: false 
    };
}

const pool = new Pool(dbConfig);

pool.on('connect', () => console.log('✅ Connected to Supabase PostgreSQL Database Pool.'));
pool.on('error', (err) => console.error('❌ Unexpected Database Pool Error:', err.message));

const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET;

// ==========================================
// 🔐 SECURITY & AUTHORIZATION GATEKEEPER
// ==========================================
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) return res.status(401).json({ error: "Access Denied: Missing identity token." });

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) return res.status(403).json({ error: "Access Forbidden: Invalid token." });
        req.ownerId = user.ownerId;
        next();
    });
};

// ==========================================
// 🚀 ENDPOINT 1: USER WORKSPACE REGISTRATION (SIGNUP)
// ==========================================
app.post('/v1/auth/signup', async (req, res) => {
    const { gym_name, name, phone, email, password } = req.body;

    if (!gym_name || !name || !email || !password) {
        return res.status(400).json({ error: "Missing required registration parameters." });
    }

    const client = await pool.connect();
    try {
        await client.query('BEGIN'); 

        const saltRounds = 10;
        const hashedPassword = await bcrypt.hash(password, saltRounds);

        const ownerInsertQuery = `
            INSERT INTO owners (name, email, password_hash, phone) 
            VALUES ($1, $2, $3, $4) 
            RETURNING id;
        `;
        const ownerResult = await client.query(ownerInsertQuery, [name, email.toLowerCase().trim(), hashedPassword, phone]);
        const newOwnerId = ownerResult.rows[0].id;

        const gymInsertQuery = `
            INSERT INTO gyms (owner_id, name, is_primary) 
            VALUES ($1, $2, true) 
            RETURNING id;
        `;
        const gymResult = await client.query(gymInsertQuery, [newOwnerId, gym_name]);
        const newGymId = gymResult.rows[0].id;

        await client.query('COMMIT'); 

        const token = jwt.sign({ ownerId: newOwnerId }, JWT_SECRET, { expiresIn: '30d' });

        return res.status(201).json({
            token: token,
            owner_id: newOwnerId,
            primary_gym_id: newGymId,
            owner_name: name
        });

    } catch (err) {
        await client.query('ROLLBACK').catch(() => {}); 
        console.error("Signup Transaction Layer Crash:", err);
        if (err.code === '23505') {
            return res.status(409).json({ error: "An account with this email address already exists." });
        }
        return res.status(500).json({ error: "Internal workspace initialization failure." });
    } finally {
        client.release();
    }
});

// ==========================================
// 🚀 ENDPOINT 2: USER WORKSPACE LOGIN GATEWAY
// ==========================================
app.post('/v1/auth/login', async (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({ error: "Email and password are mandatory." });
    }

    try {
        const ownerResult = await pool.query('SELECT * FROM owners WHERE email = $1 LIMIT 1', [email.toLowerCase().trim()]);
        if (ownerResult.rows.length === 0) {
            return res.status(401).json({ error: "Invalid credentials." });
        }
        
        const owner = ownerResult.rows[0];
        const isPasswordValid = await bcrypt.compare(password, owner.password_hash);
        if (!isPasswordValid) {
            return res.status(401).json({ error: "Invalid credentials." });
        }

        const gymResult = await pool.query('SELECT id FROM gyms WHERE owner_id = $1 AND is_primary = true LIMIT 1', [owner.id]);
        const primaryGymId = gymResult.rows[0]?.id || null;
        const token = jwt.sign({ ownerId: owner.id }, JWT_SECRET, { expiresIn: '30d' });

        return res.status(200).json({
            token: token,
            owner_id: owner.id,
            primary_gym_id: primaryGymId,
            owner_name: owner.name
        });

    } catch (err) {
        console.error("Login Engine Fault:", err);
        return res.status(500).json({ error: "Internal server error." });
    }
});

// ==========================================
// 🔄 ENDPOINT 3: REAL-TIME MASTER DASHBOARD SYNC
// ==========================================
app.get('/v1/gyms/:gymId/sync', authenticateToken, async (req, res) => {
    const gymId = parseInt(req.params.gymId);

    if (isNaN(gymId)) {
        return res.status(400).json({ error: "Malformed gym branch identifier." });
    }

    try {
        const ownershipCheck = await pool.query('SELECT id FROM gyms WHERE id = $1 AND owner_id = $2', [gymId, req.ownerId]);
        if (ownershipCheck.rows.length === 0) {
            return res.status(403).json({ error: "Access Denied." });
        }

        const [membersRes, staffRes, plansRes, expensesRes, gymsRes, attendanceRes, paymentsRes, ownerRes] = await Promise.all([
            pool.query('SELECT * FROM members WHERE gym_id = $1 ORDER BY id DESC LIMIT 200', [gymId]),
            pool.query('SELECT id, gym_id, name, role, salary, attendance_enabled FROM staff WHERE gym_id = $1 AND is_active = true', [gymId]),
            pool.query('SELECT * FROM plans WHERE gym_id = $1 ORDER BY price ASC', [gymId]),
            pool.query('SELECT * FROM expenses WHERE gym_id = $1 ORDER BY expense_date DESC LIMIT 50', [gymId]),
            pool.query('SELECT id, owner_id, name, is_primary FROM gyms WHERE owner_id = $1', [req.ownerId]),
            pool.query('SELECT * FROM attendance WHERE gym_id = $1 ORDER BY id DESC LIMIT 100', [gymId]),
            pool.query('SELECT * FROM payments WHERE gym_id = $1 ORDER BY id DESC LIMIT 100', [gymId]),
            pool.query('SELECT name, email, phone FROM owners WHERE id = $1 LIMIT 1', [req.ownerId])
        ]);

        const ownerInfo = ownerRes.rows[0] || { name: "Workspace Owner", email: "", phone: "" };

        return res.status(200).json({
            gym_id: gymId,
            owner_name: ownerInfo.name,
            owner_email: ownerInfo.email,
            owner_phone: ownerInfo.phone || "Not Provided",
            members: membersRes.rows,
            staff: staffRes.rows,
            plans: plansRes.rows,
            expenses: expensesRes.rows,
            gyms: gymsRes.rows,
            attendance: attendanceRes.rows,
            payments: paymentsRes.rows
        });

    } catch (err) {
        console.error("Master Sync Failure:", err);
        return res.status(500).json({ error: "Failed to assemble unified branch snapshot data." });
    }
});

// ==========================================
// 📥 ENDPOINT 4: RECORD INGESTION (ADD MEMBER)
// ==========================================
app.post('/v1/gyms/:gymId/members', authenticateToken, async (req, res) => {
    const gymId = parseInt(req.params.gymId);
    const m = req.body;

    if (isNaN(gymId)) {
        return res.status(400).json({ error: "Malformed branch parameters." });
    }

    try {
        const ownershipCheck = await pool.query('SELECT id FROM gyms WHERE id = $1 AND owner_id = $2', [gymId, req.ownerId]);
        if (ownershipCheck.rows.length === 0) {
            return res.status(403).json({ error: "Unauthorized access." });
        }

        const insertQuery = `
            INSERT INTO members (gym_id, membership_number, name, phone, gender, email, address, joined_date, due_amount, status)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
            RETURNING id;
        `;

        const values = [
            gymId,
            m.membershipNumber,
            m.name,
            m.phone,
            m.gender,
            m.email,
            m.address,
            m.joinedDate || new Date(),
            m.dueAmount || 0.0,
            m.status || 'ACTIVE'
        ];

        const executionResult = await pool.query(insertQuery, values);
        return res.status(201).json({ 
            success: true, 
            inserted_id: executionResult.rows[0].id 
        });

    } catch (err) {
        console.error("Ingestion Layer Fault:", err);
        return res.status(500).json({ error: "Failed to insert profile record." });
    }
});

// ==========================================
// 📥 ENDPOINT 5: CATALOG INGESTION (ADD PLAN)
// ==========================================
app.post('/v1/gyms/:gymId/plans', authenticateToken, async (req, res) => {
    const gymId = parseInt(req.params.gymId);
    const p = req.body;

    if (isNaN(gymId)) {
        return res.status(400).json({ error: "Malformed branch parameters." });
    }

    try {
        const ownershipCheck = await pool.query('SELECT id FROM gyms WHERE id = $1 AND owner_id = $2', [gymId, req.ownerId]);
        if (ownershipCheck.rows.length === 0) {
            return res.status(403).json({ error: "Unauthorized access to this branch." });
        }

        const insertQuery = `
            INSERT INTO plans (gym_id, name, price, duration_value, duration_type)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING id;
        `;

        const values = [
            gymId,
            p.name,
            p.price || 0.0,
            p.durationValue || 1,
            p.durationType || 'months'
        ];

        const executionResult = await pool.query(insertQuery, values);
        return res.status(201).json({ 
            success: true, 
            inserted_id: executionResult.rows[0].id 
        });

    } catch (err) {
        console.error("🔥 Plan Insertion Engine Fault:", err);
        return res.status(500).json({ error: "Failed to create new membership plan asset." });
    }
});

// ==========================================
// 📥 PRODUCTION SAFE: LOG MEMBER ATTENDANCE
// ==========================================
app.post('/v1/gyms/:gymId/attendance', authenticateToken, async (req, res) => {
    const gymId = parseInt(req.params.gymId);
    const { memberId } = req.body; 

    if (isNaN(gymId) || !memberId) {
        return res.status(400).json({ error: "Missing or malformed identifiers." });
    }

    try {
        const ownershipCheck = await pool.query(
            'SELECT id FROM gyms WHERE id = $1 AND owner_id = $2', 
            [gymId, req.ownerId]
        );
        
        if (ownershipCheck.rows.length === 0) {
            return res.status(403).json({ error: "Unauthorized access to this gym branch." });
        }

        const duplicateCheck = await pool.query(
            'SELECT id FROM attendance WHERE gym_id = $1 AND member_id = $2 AND attendance_date = CURRENT_DATE',
            [gymId, parseInt(memberId)]
        );

        if (duplicateCheck.rows.length > 0) {
            return res.status(409).json({ error: "Attendance has already been marked for this member today." });
        }

        const insertQuery = `
            INSERT INTO attendance (gym_id, member_id, attendance_date)
            VALUES ($1, $2, CURRENT_DATE)
            RETURNING id, attendance_date;
        `;
        
        const result = await pool.query(insertQuery, [gymId, parseInt(memberId)]);

        return res.status(201).json({ 
            success: true, 
            attendance_id: result.rows[0].id 
        });
    } catch (err) {
        console.error("🔥 SYSTEM FAILURE IN ATTENDANCE ROUTE:", err);
        return res.status(500).json({ error: "Internal database tracking fault." });
    }
});

app.listen(PORT, () => console.log(`🚀 ProLine Backend Operational on Node Port: ${PORT}`));