const path = require("path")
const webpack = require("webpack")
const src = path.join(__dirname, "src")

/*
module.exports = {
  devtool: 'sourcemap',
  entry: [
    'webpack-dev-server/client?http://localhost:3000',
    'webpack/hot/only-dev-server',
    './src/index'
  ],
  output: {
    path: path.join(__dirname, 'www'),
    filename: 'trello-mx.js',
    sourceMapFilename: 'trello-mx.map'
  },
  module: {
    loaders: [{
      test: /\.jsx?$/,
      loader: 'babel',
      include: src
    }]
  },
  plugins: [
    new webpack.HotModuleReplacementPlugin(),
    new webpack.NoErrorsPlugin()
  ],
  resolve: {
    root: src,
    extensions: ['', '.js', '.jsx']
  },
  eslint: {
    configFile: '.eslintrc'
  }
}
*/

module.exports = {
  devtool: "sourcemap",
  entry: [
    //'webpack-hot-middleware/client',
    "./src/index"
  ],
  output: {
    path: path.join(__dirname, "www"),
    filename: "bundle.js",
    sourceMapFilename: "trello-mx.map"
  },
  plugins: [
    new webpack.optimize.OccurenceOrderPlugin()
    //new webpack.HotModuleReplacementPlugin()
    //new webpack.NoErrorsPlugin()
  ],
  module: {
    loaders: [
      {
        test: /\.jsx?$/,
        loaders: [ "babel" ],
        exclude: /node_modules/,
        include: src
      },
      {
        test: /\.json/,
        loader: "json"
      }
    ]
  }
}
