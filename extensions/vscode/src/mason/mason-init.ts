import * as vscode from "vscode";
import { masonExec, statusBarTimeout } from ".";

export const masonInit = async ({ cwd }: { cwd: string }): Promise<void> => {
  return vscode.window.withProgress(
    {
      location: vscode.ProgressLocation.Window,
      title: "mason init",
    },
    async (_) => {
      try {
        await masonExec("init", {
          cwd: cwd,
        });
        vscode.window.setStatusBarMessage("✓ mason init", statusBarTimeout);
      } catch (err) {
        vscode.window.showErrorMessage(`${err}`);
      }
    }
  );
};
