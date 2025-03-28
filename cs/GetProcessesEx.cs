using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;

namespace GetProcessesEx
{
	class MapDeviceName
	{
		[DllImport("Kernel32.dll", CharSet = CharSet.Unicode)]
		private static extern uint QueryDosDevice([In] string lpDeviceName, [Out] StringBuilder lpTargetPath, [In] int ucchMax);

		public MapDeviceName()
		{
			StringBuilder buffer = new StringBuilder(128);
			foreach (DriveInfo drive in DriveInfo.GetDrives())
			{
				String driveLetter = drive.Name.Substring(0, 2);
				if (0 == QueryDosDevice(driveLetter, buffer, buffer.Capacity))
					continue;

				m_NtToDos.Add(buffer.ToString() + "\\", driveLetter + "\\");
			}
		}

		public String MapPath(String a_path)
		{
			foreach (String ntDevice in m_NtToDos.Keys)
			{
				if (a_path.StartsWith(ntDevice))
					return m_NtToDos[ntDevice] + a_path.Substring(ntDevice.Length);
			}

			return a_path;
		}

		Dictionary<string, string> m_NtToDos = new Dictionary<string, string>();
	}

	static class GetProcessExePath
	{

		[StructLayout(LayoutKind.Sequential)]
		public struct UNICODE_STRING
		{
			public ushort Length;
			public ushort MaximumLength;
			public IntPtr Buffer;
		}

		[StructLayout(LayoutKind.Sequential)]
		public struct SystemProcessIdInformation
		{
			public IntPtr ProcessId;
			public UNICODE_STRING ImageName;
		};

		public enum SystemInformationClass
		{
			SystemProcessIdInformation = 88,
		}

		[DllImport("ntdll.dll")]
		public static extern int NtQuerySystemInformation(
			SystemInformationClass SystemInformationClass,
			ref SystemProcessIdInformation SystemInformation,
			int SystemInformationLength,
			IntPtr ReturnLength
		);

		private static ushort m_MaxPathLen = 1024;
		private static IntPtr m_buffer = Marshal.AllocHGlobal(m_MaxPathLen * 2);

		public static String Get(int a_pid)
		{
			SystemProcessIdInformation info = new SystemProcessIdInformation()
			{
				ProcessId = new IntPtr(a_pid),
				ImageName = new UNICODE_STRING()
				{
					Length = 0,
					MaximumLength = (ushort)(m_MaxPathLen * 2),
					Buffer = m_buffer,
				}
			};

			int infoLength = Marshal.SizeOf(info);
			int status = NtQuerySystemInformation(
				SystemInformationClass.SystemProcessIdInformation,
				ref info,
				infoLength,
				IntPtr.Zero
			);

			if (status < 0)
				return "";

			String result = Marshal.PtrToStringUni(m_buffer, info.ImageName.Length / 2);
			switch (result)
			{
				case "Registry":
				case "MemCompression":
				case "vmmemCmZygote":
					return "";
			}

			return result;
		}
	}

	public class ProcessInfo
	{
		public Process Process;
		public String ExePath;
	}

	public static class Processes
	{
		public static ProcessInfo[] Get()
		{
			Process[] processes = Process.GetProcesses();
			ProcessInfo[] result = new ProcessInfo[processes.Length];
			MapDeviceName mapDeviceName = new MapDeviceName();

			for (int i = 0; i < processes.Length; i++)
			{
				Process process = processes[i];
				String ntPath = GetProcessExePath.Get(process.Id);
				String dosPath = mapDeviceName.MapPath(ntPath);

				result[i] = new ProcessInfo()
				{
					Process = process,
					ExePath = dosPath,
				};
			}

			return result;
		}
	}

	class Test
	{
		public static void Main()
		{
			ProcessInfo[] processes = Processes.Get();

			foreach (ProcessInfo process in processes)
			{
				Console.WriteLine("{0:D5} : {1}", process.Process.Id, process.ExePath);
			}
		}
	}
}
