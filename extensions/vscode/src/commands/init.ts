import * as vscode from "vscode";
import * as path from "path";
import { masonInit } from "../mason";

export const init = async () => {
  const folder = vscode.workspace.workspaceFolders?.[0];
  if (!folder) return;
  try {
    const masonYamlPath = path.join(folder.uri.fsPath, "mason.yaml");
    await vscode.workspace.fs.stat(vscode.Uri.file(masonYamlPath));
    vscode.window.showErrorMessage(
      "A mason.yaml already exists in the current workspace."
    );
    return;
  } catch (_) {}

  await masonInit({ cwd: folder.uri.fsPath });
};
