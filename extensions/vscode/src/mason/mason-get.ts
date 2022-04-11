import * as vscode from "vscode";
import { exec } from "../utils";

export const masonGet = async ({ cwd }: { cwd: string }): Promise<void> => {
  return vscode.window.withProgress(
    {
      location: vscode.ProgressLocation.Window,
      title: "mason get",
    },
    async (_) => {
      try {
        await exec("mason get", {
          cwd: cwd,
        });
        vscode.window.setStatusBarMessage("✓ mason get", 1000);
      } catch (err) {
        vscode.window.showErrorMessage(`${err}`);
      }
    }
  );
};
