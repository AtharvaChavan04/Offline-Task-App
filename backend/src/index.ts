import express from 'express';
import authRouter from './routes/auth';
import taskRouter from './routes/tasks';

const app = express();

app.use(express.json());
app.use("/auth", authRouter);
app.use("/tasks", taskRouter);

app.get('/', (req, res) => {
    res.send('Hello, World!! This is my backend server.');
});

// Export for Vercel serverless functions
export default app;

// For local development
if (process.env.NODE_ENV !== 'production') {
    const PORT = process.env.PORT || 8000;
    app.listen(PORT, () => {
        console.log(`Server is running on http://localhost:${PORT}`);
    });
}