import { desc } from 'drizzle-orm';
import { pgTable, uuid, text, timestamp } from 'drizzle-orm/pg-core';

export const user = pgTable("users", {
    id: uuid("id").primaryKey().defaultRandom(),
    name: text("name").notNull(),
    email: text("email").notNull().unique(),
    password: text("password").notNull(),
    createdAt: timestamp("created_at").defaultNow(),
    updatedAt: timestamp("updated_at").defaultNow(),
});

export type User = typeof user.$inferSelect;
export type NewUser = typeof user.$inferInsert;


export const tasks = pgTable("tasks", {
    id: uuid("id").primaryKey().defaultRandom(),
    title: text("title").notNull(),
    description: text("description").notNull(),
    hexColor: text("hex_color").notNull(),
    uid: uuid("uid").notNull().references(() => user.id, { onDelete: 'cascade' }),
    dueAt: timestamp("due_at").$default(() => new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)),
    createdAt: timestamp("created_at").defaultNow(),
    updatedAt: timestamp("updated_at").defaultNow(),
})

export type Task = typeof tasks.$inferSelect;
export type NewTask = typeof tasks.$inferInsert;