import * as _ from "lodash";
import * as vscode from "vscode";
import * as path from "path";
import { masonInit } from "../mason";

export const init = async () => {
  const cwd = vscode.workspace.workspaceFolders?.[0].uri.fsPath;
  if (_.isNil(cwd)) {
    return;
  }

  try {
    const masonYamlPath = path.join(cwd, "mason.yaml");
    await vscode.workspace.fs.stat(vscode.Uri.file(masonYamlPath));
    vscode.window.showErrorMessage(
      "A mason.yaml already exists in the current workspace."
    );
    return;
  } catch (_) {}

  await masonInit({ cwd });
};
