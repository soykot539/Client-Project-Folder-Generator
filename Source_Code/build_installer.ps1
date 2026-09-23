Set-Location $PSScriptRoot

$csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
$icoPath = Join-Path $PSScriptRoot "app.ico"

# 1. Compile Core App with Icon
& $csc /target:winexe /optimize+ /win32icon:$icoPath /out:ClientProjectGenerator.exe ClientProjectGenerator.cs

# 2. Compile Uninstaller with Icon
& $csc /target:winexe /optimize+ /win32icon:$icoPath /out:Uninstall.exe Uninstall.cs

# 3. Read Binaries
$appBytes = [System.IO.File]::ReadAllBytes((Join-Path $PSScriptRoot "ClientProjectGenerator.exe"))
$appB64 = [Convert]::ToBase64String($appBytes)

$unBytes = [System.IO.File]::ReadAllBytes((Join-Path $PSScriptRoot "Uninstall.exe"))
$unB64 = [Convert]::ToBase64String($unBytes)

$icoBytes = [System.IO.File]::ReadAllBytes($icoPath)
$icoB64 = [Convert]::ToBase64String($icoBytes)

$codeTemplate = @'
using System;
using System.IO;
using System.Drawing;
using System.Windows.Forms;
using System.Diagnostics;
using Microsoft.Win32;

namespace ClientProjectGeneratorInstaller
{
    static class Program
    {
        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new InstallerForm());
        }
    }

    public class InstallerForm : Form
    {
        private TextBox txtInstallPath;
        private CheckBox chkRightClick;
        private CheckBox chkDesktopShortcut;
        private CheckBox chkStartMenu;
        private CheckBox chkLaunchNow;
        private ProgressBar progressBar;
        private Label lblStatus;
        private Button btnInstall;

        private static string AppBinaryBase64 = "__APP_B64__";
        private static string UninstallerBinaryBase64 = "__UNINSTALLER_B64__";
        private static string IconBinaryBase64 = "__ICO_B64__";

        public InstallerForm()
        {
            try
            {
                this.Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath);
            }
            catch {}

            InitializeComponents();
        }

        private void InitializeComponents()
        {
            this.Text = "Client Project Folder Generator Setup";
            this.Size = new Size(520, 560);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.BackColor = Color.FromArgb(28, 30, 36);
            this.ForeColor = Color.FromArgb(230, 235, 245);
            this.Font = new Font("Segoe UI", 9.5f);

            Panel pnlHeader = new Panel {
                Location = new Point(0, 0),
                Size = new Size(520, 80),
                BackColor = Color.FromArgb(20, 22, 27)
            };

            Label lblTitle = new Label {
                Text = "Client Project Folder Generator Setup",
                Font = new Font("Segoe UI", 13f, FontStyle.Bold),
                ForeColor = Color.FromArgb(88, 166, 255),
                Location = new Point(25, 18),
                Size = new Size(470, 28)
            };
            pnlHeader.Controls.Add(lblTitle);

            Label lblSub = new Label {
                Text = "Version 2.0.0  •  Developed by Soikot  •  Official Installer",
                Font = new Font("Segoe UI", 8.5f),
                ForeColor = Color.FromArgb(140, 150, 165),
                Location = new Point(27, 48),
                Size = new Size(470, 20)
            };
            pnlHeader.Controls.Add(lblSub);
            this.Controls.Add(pnlHeader);

            int y = 95;

            GroupBox grpPath = new GroupBox {
                Text = " Destination Folder (C: Drive) ",
                ForeColor = Color.FromArgb(200, 210, 225),
                Location = new Point(20, y),
                Size = new Size(465, 95),
                BackColor = Color.FromArgb(35, 38, 46)
            };

            string defaultPath = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                @"Programs\Client Project Folder Generator"
            );

            txtInstallPath = new TextBox {
                Text = defaultPath,
                Location = new Point(15, 30),
                Size = new Size(375, 24),
                BackColor = Color.FromArgb(45, 49, 60),
                ForeColor = Color.White
            };
            grpPath.Controls.Add(txtInstallPath);

            Button btnBrowse = new Button {
                Text = "...",
                Location = new Point(398, 29),
                Size = new Size(52, 26),
                BackColor = Color.FromArgb(55, 60, 75),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnBrowse.Click += (s, e) => {
                using (FolderBrowserDialog fbd = new FolderBrowserDialog { Description = "Select Installation Directory" }) {
                    if (Directory.Exists(txtInstallPath.Text)) fbd.SelectedPath = txtInstallPath.Text;
                    if (fbd.ShowDialog() == DialogResult.OK) {
                        txtInstallPath.Text = Path.Combine(fbd.SelectedPath, "Client Project Folder Generator");
                    }
                }
            };
            grpPath.Controls.Add(btnBrowse);

            Label lblSpace = new Label {
                Text = "Space required: 2.5 MB  |  Standard Windows Application Install",
                Location = new Point(15, 65),
                Size = new Size(430, 20),
                Font = new Font("Segoe UI", 8f),
                ForeColor = Color.FromArgb(140, 150, 165)
            };
            grpPath.Controls.Add(lblSpace);
            this.Controls.Add(grpPath);

            y += 105;

            GroupBox grpOpts = new GroupBox {
                Text = " Installation Options ",
                ForeColor = Color.FromArgb(200, 210, 225),
                Location = new Point(20, y),
                Size = new Size(465, 125),
                BackColor = Color.FromArgb(35, 38, 46)
            };

            chkRightClick = new CheckBox {
                Text = "Integrate with Windows Right-Click Context Menu (*)",
                Checked = true,
                Location = new Point(15, 25),
                Size = new Size(430, 24),
                ForeColor = Color.FromArgb(88, 166, 255)
            };
            grpOpts.Controls.Add(chkRightClick);

            chkDesktopShortcut = new CheckBox {
                Text = "Create a Desktop Shortcut",
                Checked = true,
                Location = new Point(15, 55),
                Size = new Size(220, 24),
                ForeColor = Color.FromArgb(220, 225, 235)
            };
            grpOpts.Controls.Add(chkDesktopShortcut);

            chkStartMenu = new CheckBox {
                Text = "Create Start Menu Shortcut",
                Checked = true,
                Location = new Point(235, 55),
                Size = new Size(220, 24),
                ForeColor = Color.FromArgb(220, 225, 235)
            };
            grpOpts.Controls.Add(chkStartMenu);

            chkLaunchNow = new CheckBox {
                Text = "Launch Client Project Folder Generator after installation",
                Checked = true,
                Location = new Point(15, 88),
                Size = new Size(430, 24),
                ForeColor = Color.FromArgb(220, 225, 235)
            };
            grpOpts.Controls.Add(chkLaunchNow);

            this.Controls.Add(grpOpts);

            y += 135;

            lblStatus = new Label {
                Text = "Ready to install.",
                Location = new Point(20, y),
                Size = new Size(465, 20),
                ForeColor = Color.FromArgb(170, 180, 195)
            };
            this.Controls.Add(lblStatus);

            y += 25;

            progressBar = new ProgressBar {
                Location = new Point(20, y),
                Size = new Size(465, 20),
                Style = ProgressBarStyle.Blocks,
                Value = 0
            };
            this.Controls.Add(progressBar);

            y += 35;

            btnInstall = new Button {
                Text = "INSTALL NOW",
                Font = new Font("Segoe UI", 11f, FontStyle.Bold),
                Location = new Point(20, y),
                Size = new Size(465, 46),
                BackColor = Color.FromArgb(35, 134, 54),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat,
                Cursor = Cursors.Hand
            };
            btnInstall.Click += (s, e) => PerformInstall();
            this.Controls.Add(btnInstall);
        }

        private void PerformInstall()
        {
            btnInstall.Enabled = false;
            string targetDir = txtInstallPath.Text.Trim();

            try
            {
                lblStatus.Text = "Extracting files to C: Drive...";
                progressBar.Value = 25;
                Application.DoEvents();

                if (!Directory.Exists(targetDir))
                {
                    Directory.CreateDirectory(targetDir);
                }

                string mainExe = Path.Combine(targetDir, "ClientProjectGenerator.exe");
                string uninstallerExe = Path.Combine(targetDir, "Uninstall.exe");
                string appIconFile = Path.Combine(targetDir, "app.ico");

                byte[] appB = Convert.FromBase64String(AppBinaryBase64);
                File.WriteAllBytes(mainExe, appB);

                byte[] unB = Convert.FromBase64String(UninstallerBinaryBase64);
                File.WriteAllBytes(uninstallerExe, unB);

                byte[] icoB = Convert.FromBase64String(IconBinaryBase64);
                File.WriteAllBytes(appIconFile, icoB);

                progressBar.Value = 50;
                lblStatus.Text = "Configuring Windows Registry and Shortcuts...";
                Application.DoEvents();

                if (chkRightClick.Checked)
                {
                    string menuName = "Create Client Project Folder";

                    using (RegistryKey key = Registry.CurrentUser.CreateSubKey(@"Software\Classes\Directory\Background\shell\ClientProjectGenerator"))
                    {
                        if (key != null)
                        {
                            key.SetValue("", menuName);
                            key.SetValue("Icon", mainExe + ",0");
                            using (RegistryKey cmdKey = key.CreateSubKey("command"))
                            {
                                if (cmdKey != null) cmdKey.SetValue("", "\"" + mainExe + "\"");
                            }
                        }
                    }

                    using (RegistryKey key = Registry.CurrentUser.CreateSubKey(@"Software\Classes\Directory\shell\ClientProjectGenerator"))
                    {
                        if (key != null)
                        {
                            key.SetValue("", menuName);
                            key.SetValue("Icon", mainExe + ",0");
                            using (RegistryKey cmdKey = key.CreateSubKey("command"))
                            {
                                if (cmdKey != null) cmdKey.SetValue("", "\"" + mainExe + "\"");
                            }
                        }
                    }
                }

                if (chkDesktopShortcut.Checked)
                {
                    string desktop = Environment.GetFolderPath(Environment.SpecialFolder.Desktop);
                    CreateShortcut(Path.Combine(desktop, "Client Project Folder Generator.lnk"), mainExe, targetDir, mainExe);
                }

                if (chkStartMenu.Checked)
                {
                    string startMenu = Environment.GetFolderPath(Environment.SpecialFolder.Programs);
                    CreateShortcut(Path.Combine(startMenu, "Client Project Folder Generator.lnk"), mainExe, targetDir, mainExe);
                }

                progressBar.Value = 75;
                lblStatus.Text = "Registering in Windows Control Panel...";
                Application.DoEvents();

                using (RegistryKey uKey = Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\CurrentVersion\Uninstall\ClientProjectGenerator"))
                {
                    if (uKey != null)
                    {
                        uKey.SetValue("DisplayName", "Client Project Folder Generator");
                        uKey.SetValue("DisplayVersion", "2.0.0");
                        uKey.SetValue("Publisher", "Soikot");
                        uKey.SetValue("DisplayIcon", mainExe + ",0");
                        uKey.SetValue("UninstallString", "\"" + uninstallerExe + "\"");
                        uKey.SetValue("QuietUninstallString", "\"" + uninstallerExe + "\" /silent");
                        uKey.SetValue("InstallLocation", targetDir);
                        uKey.SetValue("EstimatedSize", 2560, RegistryValueKind.DWord);
                        uKey.SetValue("InstallDate", DateTime.Now.ToString("yyyyMMdd"));
                    }
                }

                progressBar.Value = 100;
                lblStatus.Text = "Installation Completed Successfully!";
                Application.DoEvents();

                MessageBox.Show(
                    "Client Project Folder Generator has been successfully installed on your computer!\n\n" +
                    "Installed Location:\n" + targetDir + "\n\n" +
                    "• Right-click anywhere in Windows Explorer to create client projects instantly.\n" +
                    "• Features top Menu bar, System/White/Black themes & full Copyright protection.\n" +
                    "• To uninstall anytime, go to Windows Settings > Apps or Control Panel.",
                    "Setup Complete",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Information
                );

                if (chkLaunchNow.Checked)
                {
                    Process.Start(mainExe);
                }

                this.Close();
            }
            catch (Exception ex)
            {
                btnInstall.Enabled = true;
                MessageBox.Show("Installation failed: " + ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private static void CreateShortcut(string shortcutPath, string targetPath, string workingDir, string iconPath)
        {
            try
            {
                Type shellType = Type.GetTypeFromProgID("WScript.Shell");
                dynamic shell = Activator.CreateInstance(shellType);
                dynamic shortcut = shell.CreateShortcut(shortcutPath);
                shortcut.TargetPath = targetPath;
                shortcut.WorkingDirectory = workingDir;
                shortcut.IconLocation = iconPath + ",0";
                shortcut.Description = "Client Project Folder Generator by Soikot";
                shortcut.Save();
            }
            catch {}
        }
    }
}
'@

$finalCode = $codeTemplate.Replace('__APP_B64__', $appB64).Replace('__UNINSTALLER_B64__', $unB64).Replace('__ICO_B64__', $icoB64)
$csPath = Join-Path $PSScriptRoot "Setup_ClientProjectGenerator.cs"
[System.IO.File]::WriteAllText($csPath, $finalCode, [System.Text.Encoding]::UTF8)

# 4. Compile Final Installer with Icon
$parentDir = Split-Path -Path $PSScriptRoot -Parent
$setupExe = Join-Path $parentDir "Setup_ClientProjectGenerator.exe"
& $csc /target:winexe /optimize+ "/win32icon:$icoPath" "/out:$setupExe" "$csPath"

# Clean up intermediate binaries in source folder
Remove-Item -Path (Join-Path $PSScriptRoot "ClientProjectGenerator.exe") -Force -ErrorAction SilentlyContinue
Remove-Item -Path (Join-Path $PSScriptRoot "Uninstall.exe") -Force -ErrorAction SilentlyContinue

if (Test-Path $setupExe) {
    Write-Host "REBUILD_COMPLETE_SUCCESS: $setupExe"
} else {
    Write-Error "BUILD_FAILED"
}
