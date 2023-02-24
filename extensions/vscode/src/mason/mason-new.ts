import * as vscode from "vscode";
import { masonExec, statusBarTimeout } from ".";

export const masonNew = async ({
  targetDirectory,
  brick,
  hooks = false,
}: {
  targetDirectory: string;
  brick: string;
  hooks?: boolean;
}): Promise<void> => {
  return vscode.window.withProgress(
    {
      location: vscode.ProgressLocation.Window,
      title: `mason new ${brick} ${hooks ? "--hooks" : ""}`,
    },
    async (_) => {
      try {
        await masonExec(`new ${brick} ${hooks ? "--hooks" : ""}`, {
          cwd: targetDirectory,
        });
        vscode.window.setStatusBarMessage(
          `✓ mason new ${brick} ${hooks ? "--hooks" : ""}`,
          statusBarTimeout
        );
      } catch (err) {
        vscode.window.showErrorMessage(`${err}`);
      }
    }
  );
};
