<?php

namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

class ProcessEmailQueue implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public $tries = 3;
    public $maxExceptions = 3;
    public $timeout = 120;

    protected $recipient;
    protected $subject;
    protected $message;

    /**
     * Create a new job instance.
     */
    public function __construct(string $recipient, string $subject, string $message)
    {
        $this->recipient = $recipient;
        $this->subject = $subject;
        $this->message = $message;
    }

    /**
     * Execute the job.
     */
    public function handle(): void
    {
        try {
            Log::info('Processing email job', [
                'recipient' => $this->recipient,
                'subject' => $this->subject,
            ]);

            // Simulate email processing
            // In a real application, you would use Laravel's Mail facade
            // Mail::to($this->recipient)->send(new YourMailableClass($this->message));

            // For demonstration, we'll just log the action
            Log::info('Email sent successfully', [
                'recipient' => $this->recipient,
                'subject' => $this->subject,
                'message' => $this->message,
            ]);

            // Simulate processing time
            sleep(2);

        } catch (\Exception $e) {
            Log::error('Failed to process email job', [
                'recipient' => $this->recipient,
                'subject' => $this->subject,
                'error' => $e->getMessage(),
            ]);

            throw $e;
        }
    }

    /**
     * Handle a job failure.
     */
    public function failed(\Throwable $exception): void
    {
        Log::error('Email job failed permanently', [
            'recipient' => $this->recipient,
            'subject' => $this->subject,
            'error' => $exception->getMessage(),
        ]);
    }
}
