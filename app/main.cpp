#include <windows.h>
#include <tlhelp32.h>
#include <string>
#include <vector>
#include <ctime>

#define ID_BTN_APACHE 1
#define ID_BTN_MYSQL 2
#define ID_LOG_LIST 3
#define TIMER_ID 100
#define IDI_APP_ICON 101

const std::string apacheExe = "httpd.exe";
const std::string apachePath = "C:\\xampp\\apache\\bin\\httpd.exe";

const std::string mysqlExe = "mysqld.exe";
const std::string mysqlPath = "C:\\xampp\\mysql\\bin\\mysqld.exe";

HWND hApacheBtn, hMySQLBtn, hApacheLbl, hMySQLLbl, hLogList;
HINSTANCE hInst;

bool IsProcessRunning(const std::string &name)
{
    PROCESSENTRY32 entry;
    entry.dwSize = sizeof(PROCESSENTRY32);
    HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);

    if (snapshot == INVALID_HANDLE_VALUE)
        return false;

    if (Process32First(snapshot, &entry))
    {
        do
        {
            if (name == entry.szExeFile)
            {
                CloseHandle(snapshot);
                return true;
            }
        } while (Process32Next(snapshot, &entry));
    }

    CloseHandle(snapshot);
    return false;
}

void Log(const std::string &msg)
{
    time_t now = time(0);
    tm *lt = localtime(&now);
    char timestamp[9];
    strftime(timestamp, sizeof(timestamp), "%H:%M:%S", lt);

    std::string fullMsg = "[" + std::string(timestamp) + "] " + msg;
    SendMessageA(hLogList, LB_ADDSTRING, 0, (LPARAM)fullMsg.c_str());
    int count = SendMessage(hLogList, LB_GETCOUNT, 0, 0);
    SendMessage(hLogList, LB_SETTOPINDEX, count - 1, 0);
}

void UpdateStatus()
{
    if (IsProcessRunning(apacheExe))
    {
        SetWindowTextA(hApacheLbl, "Apache Status: Running");
        SetWindowTextA(hApacheBtn, "Stop");
    }
    else
    {
        SetWindowTextA(hApacheLbl, "Apache Status: Stopped");
        SetWindowTextA(hApacheBtn, "Start");
    }

    if (IsProcessRunning(mysqlExe))
    {
        SetWindowTextA(hMySQLLbl, "MySQL Status: Running");
        SetWindowTextA(hMySQLBtn, "Stop");
    }
    else
    {
        SetWindowTextA(hMySQLLbl, "MySQL Status: Stopped");
        SetWindowTextA(hMySQLBtn, "Start");
    }
}

void ToggleService(const std::string &exe, const std::string &path, HWND button, const std::string &label, const std::string &serviceName)
{
    EnableWindow(button, FALSE);

    if (IsProcessRunning(exe))
    {
        Log("Stopping " + serviceName);
        HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
        PROCESSENTRY32 entry;
        entry.dwSize = sizeof(entry);

        if (Process32First(snapshot, &entry))
        {
            do
            {
                if (exe == entry.szExeFile)
                {
                    HANDLE hProc = OpenProcess(PROCESS_TERMINATE, FALSE, entry.th32ProcessID);
                    if (hProc)
                    {
                        TerminateProcess(hProc, 0);
                        CloseHandle(hProc);
                    }
                    break;
                }
            } while (Process32Next(snapshot, &entry));
        }
        CloseHandle(snapshot);
    }
    else
    {
        Log("Starting " + serviceName);
        STARTUPINFOA si = {sizeof(si)};
        PROCESS_INFORMATION pi;
        CreateProcessA(NULL, (LPSTR)path.c_str(), NULL, NULL, FALSE, CREATE_NO_WINDOW, NULL, NULL, &si, &pi);
        CloseHandle(pi.hProcess);
        CloseHandle(pi.hThread);
    }

    // Sleep(1000);
    UpdateStatus();

    // if (IsProcessRunning(exe))
    //     Log(serviceName + " is running");
    // else
    //     Log(serviceName + " is stopped");

    EnableWindow(button, TRUE);
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    switch (msg)
    {
    case WM_CREATE:
    {
        hApacheLbl = CreateWindow("STATIC", "Apache Status: Checking...", WS_VISIBLE | WS_CHILD,
                                  30, 20, 350, 20, hwnd, NULL, hInst, NULL);
        hApacheBtn = CreateWindow("BUTTON", "Start", WS_VISIBLE | WS_CHILD,
                                  30, 50, 80, 30, hwnd, (HMENU)ID_BTN_APACHE, hInst, NULL);

        hMySQLLbl = CreateWindow("STATIC", "MySQL Status: Checking...", WS_VISIBLE | WS_CHILD,
                                 30, 100, 350, 20, hwnd, NULL, hInst, NULL);
        hMySQLBtn = CreateWindow("BUTTON", "Start", WS_VISIBLE | WS_CHILD,
                                 30, 130, 80, 30, hwnd, (HMENU)ID_BTN_MYSQL, hInst, NULL);

        hLogList = CreateWindow("LISTBOX", NULL, WS_VISIBLE | WS_CHILD | WS_BORDER | WS_VSCROLL,
                                30, 180, 530, 160, hwnd, (HMENU)ID_LOG_LIST, hInst, NULL);

        SetTimer(hwnd, TIMER_ID, 2000, NULL);
        UpdateStatus();
    }
    break;

    case WM_COMMAND:
        switch (LOWORD(wParam))
        {
        case ID_BTN_APACHE:
            ToggleService(apacheExe, apachePath, hApacheBtn, "Apache Status", "Apache");
            break;
        case ID_BTN_MYSQL:
            ToggleService(mysqlExe, mysqlPath, hMySQLBtn, "MySQL Status", "MySQL");
            break;
        }
        break;

    case WM_TIMER:
        if (wParam == TIMER_ID)
            UpdateStatus();
        break;

    case WM_DESTROY:
        KillTimer(hwnd, TIMER_ID);
        PostQuitMessage(0);
        break;
    }
    return DefWindowProc(hwnd, msg, wParam, lParam);
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE, LPSTR, int)
{
    hInst = hInstance;

    WNDCLASSEX wc = {};
    wc.cbSize = sizeof(WNDCLASSEX);
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInstance;
    wc.lpszClassName = "XamppControlClass";
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW);

    HICON hAppIcon = NULL;
    HICON hAppIconSm = NULL;

    // Extract the icon from the current executable
    char modulePath[MAX_PATH + 1];
    if (GetModuleFileNameA(NULL, modulePath, MAX_PATH))
    {
        ExtractIconExA(modulePath, 0, &hAppIcon, &hAppIconSm, 1);
    }

    // Taskbar and Alt+Tab icon
    wc.hIcon = hAppIcon;
    // Top-left window icon
    wc.hIconSm = hAppIcon;

    RegisterClassEx(&wc);

    // Center the window
    int winWidth = 600;
    int winHeight = 400;

    int screenWidth = GetSystemMetrics(SM_CXSCREEN);
    int screenHeight = GetSystemMetrics(SM_CYSCREEN);

    int x = (screenWidth - winWidth) / 2;
    int y = (screenHeight - winHeight) / 2;

    HWND hwnd = CreateWindow("XamppControlClass", "XAMPP Control Panel",
        WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX,
        x, y, winWidth, winHeight,
        NULL, NULL, hInstance, NULL);

    ShowWindow(hwnd, SW_SHOW);
    UpdateWindow(hwnd);

    MSG msg;
    while (GetMessage(&msg, NULL, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return 0;
}
