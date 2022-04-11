import * as path from "path";
import * as vscode from "vscode";
import { masonGet } from "../mason";

export const onFileSaved = async (document: vscode.TextDocument) => {
  if (path.basename(document.uri.fsPath) !== "mason.yaml") {
    return;
  }
  await masonGet({ cwd: path.join(document.uri.fsPath, "..") });
};
