const path = require('path')
const nodeExternals = require('webpack-node-externals')

module.exports = {
  entry: './src/index.ts',
  target: 'node',
  mode: process.env.NODE_ENV || 'development',
  externals: [nodeExternals()],
  stats: 'minimal',
  plugins: [],
  module: {
    rules: [
      {
        test: /\.ts$/,
        exclude: /node_modules/,
        include: __dirname,
        use: {
          loader: 'ts-loader',
          options: {
            transpileOnly: true
          }
        }
      }
    ]
  },
  resolve: {
    extensions: ['.ts'],
    alias: {
      '@': path.resolve(__dirname, './src')
    }
  },
  output: {
    libraryTarget: 'this',
    path: path.resolve(__dirname, 'dist'),
    filename: 'index.js'
  }
}
