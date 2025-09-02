import express from 'express';
import authRouter from './routes/auth';
import taskRouter from './routes/tasks';

const app = express();

app.use(express.json());
app.use("/auth", authRouter);
app.use("/tasks", taskRouter);

app.get('/', (req, res) => {
    res.send('Hello, World!! This is my backend server.');
})

app.listen(8000, () => {
    console.log('Server is running on http://localhost:8000');
});