import { UUID } from 'crypto';
import { NextFunction, Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { db } from '../db';
import { user } from '../db/schema';
import { eq } from 'drizzle-orm';

export interface AuthRequest extends Request {
    user?: UUID;
    token?: string;
}

export const auth = async (req: AuthRequest, res: Response, next: NextFunction) => {
    try {
        const token = req.header("x-auth-token");

        if (!token) return res.status(401).json({ error: "No authentication token, authorization denied" });

        const verified = jwt.verify(token, "passwordKey")

        if (!verified) return res.status(401).json({ error: "Token verification failed, authorization denied" });

        const verifiedToken = verified as { id: UUID };

        const [users] = await db.select().from(user).where(eq(user.id, verifiedToken.id));

        if (!users) return res.status(401).json({ error: "User does not exist, authorization denied" });

        req.user = verifiedToken.id;
        req.token = token;

        next();

    } catch (e) {
        return res.status(500).json(false);
    }
}