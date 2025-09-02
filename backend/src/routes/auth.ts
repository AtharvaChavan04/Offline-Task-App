import { Router, Request, Response } from 'express';
import { db } from '../db';
import { NewUser, user } from '../db/schema';
import { eq } from 'drizzle-orm';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { auth, AuthRequest } from '../middleware/auth';

const authRouter = Router();

interface SignUpBody {
    name: string;
    email: string;
    password: string;
}

interface LoginBody {
    email: string;
    password: string;
}

authRouter.post("/signup", async (req: Request<{}, {}, SignUpBody>, res: Response) => {
    try {
        const { name, email, password } = req.body;

        const existingUser = await db.select().from(user).where(eq(user.email, email),);

        if (existingUser.length > 0) {
            return res.status(400).json({ error: "User with same email already exists" });
        }

        const hashedPassword = await bcrypt.hash(password, 8)

        const newUser: NewUser = {
            name,
            email,
            password: hashedPassword,
        }

        const [users] = await db.insert(user).values(newUser).returning();
        return res.status(201).json({ user: users });
    } catch (e) {
        return res.status(500).json({ error: e });
    }
});

authRouter.post("/login", async (req: Request<{}, {}, LoginBody>, res: Response) => {
    try {
        const { email, password } = req.body;

        const [existingUser] = await db.select().from(user).where(eq(user.email, email),);

        if (!existingUser) {
            return res.status(400).json({ error: "User with this email does not exist!" });
        }

        const isMatch = await bcrypt.compare(password, existingUser.password);

        if (!isMatch) {
            return res.status(400).json({ error: "Invalid password!" });
        }

        const token = jwt.sign({ id: existingUser.id }, "passwordKey")

        res.json({ token, ...existingUser });
    } catch (e) {
        return res.status(500).json({ error: e });
    }
});

authRouter.post("/tokenIsValid", async (req, res) => {
    try {
        const token = req.header("x-auth-token");

        if (!token) return res.json(false);

        const verified = jwt.verify(token, "passwordKey")

        if (!verified) return res.json(false);

        const verifiedToken = verified as { id: string };

        const [users] = await db.select().from(user).where(eq(user.id, verifiedToken.id));

        if (!users) return res.json(false);

        res.json(true);

    } catch (e) {
        return res.status(500).json(false);
    }
})

authRouter.get("/", auth, async (req: AuthRequest, res) => {
    try {
        if (!req.user) {
            res.status(401).json({ error: "User not found!" });
            return;
        }

        const [users] = await db.select().from(user).where(eq(user.id, req.user));

        res.json({ ...users, token: req.token });
    } catch (e) {
        return res.status(500).json(false);
    }
});

export default authRouter;