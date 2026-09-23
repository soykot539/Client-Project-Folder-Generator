using System;
using System.IO;
using System.Drawing;
using System.Windows.Forms;
using System.Diagnostics;
using Microsoft.Win32;

namespace ClientProjectGenerator
{
    static class UninstallerProgram
    {
        [STAThread]
        static void Main(string[] args)
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            bool isSilent = args.Length > 0 && args[0].ToLower().Contains("silent");

            if (!isSilent)
            {
                DialogResult dr = MessageBox.Show(
                    "Are you sure you want to completely uninstall Client Project Folder Generator?",
                    "Uninstall Client Project Folder Generator",
                    MessageBoxButtons.YesNo,
                    MessageBoxIcon.Question
                );

                if (dr != DialogResult.Yes) return;
            }

            try
            {
                // 1. Remove Right-Click Context Menu Registry
                Registry.CurrentUser.DeleteSubKeyTree(@"Software\Classes\Directory\Background\shell\ClientProjectGenerator", false);
                Registry.CurrentUser.DeleteSubKeyTree(@"Software\Classes\Directory\shell\ClientProjectGenerator", false);

                // 2. Remove Windows Add/Remove Programs Registry
                Registry.CurrentUser.DeleteSubKeyTree(@"Software\Microsoft\Windows\CurrentVersion\Uninstall\ClientProjectGenerator", false);

                // 3. Remove Shortcuts
                string desktop = Environment.GetFolderPath(Environment.SpecialFolder.Desktop);
                string deskShortcut = Path.Combine(desktop, "Client Project Folder Generator.lnk");
                if (File.Exists(deskShortcut)) File.Delete(deskShortcut);

                string startMenu = Environment.GetFolderPath(Environment.SpecialFolder.Programs);
                string startShortcut = Path.Combine(startMenu, "Client Project Folder Generator.lnk");
                if (File.Exists(startShortcut)) File.Delete(startShortcut);

                // 4. Remove AppData config
                string appData = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
                string appDir = Path.Combine(appData, "ClientProjectGenerator");
                if (Directory.Exists(appDir)) Directory.Delete(appDir, true);

                // 5. Cleanup App Directory via delayed CMD process
                string installDir = AppDomain.CurrentDomain.BaseDirectory.TrimEnd('\\');
                
                ProcessStartInfo psi = new ProcessStartInfo();
                psi.FileName = "cmd.exe";
                psi.Arguments = string.Format("/c timeout /t 1 /nobreak >nul & rmdir /s /q \"{0}\"", installDir);
                psi.WindowStyle = ProcessWindowStyle.Hidden;
                psi.CreateNoWindow = true;
                Process.Start(psi);

                if (!isSilent)
                {
                    MessageBox.Show(
                        "Client Project Folder Generator has been successfully removed from your computer.",
                        "Uninstall Complete",
                        MessageBoxButtons.OK,
                        MessageBoxIcon.Information
                    );
                }
            }
            catch (Exception ex)
            {
                if (!isSilent)
                {
                    MessageBox.Show("Uninstall error: " + ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
        }
    }
}
