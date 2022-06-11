void main() {
  {{#flavors}}print('Running in {{.}} mode...');{{/flavors}}
}