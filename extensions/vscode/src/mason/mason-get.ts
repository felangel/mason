import * as vscode from "vscode";
import { masonExec, statusBarTimeout } from ".";

export const masonGet = async ({ cwd }: { cwd: string }): Promise<void> => {
  return vscode.window.withProgress(
    {
      location: vscode.ProgressLocation.Window,
      title: "mason get",
    },
    async (_) => {
      try {
        await masonExec("get", {
          cwd: cwd,
        });
        vscode.window.setStatusBarMessage("✓ mason get", statusBarTimeout);
      } catch (err) {
        vscode.window.showErrorMessage(`${err}`);
      }
    },
  );
};
