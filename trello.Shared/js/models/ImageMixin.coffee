# Mixin for image handling
define ->

  closenessScore = (imageWidth, imageHeight, targetWidth, targetHeight) ->
    return 0 if imageWidth is 0 or imageHeight is 0
    score = (1 + Math.abs(imageWidth - targetWidth)) * (1 + Math.abs(imageHeight - targetHeight))
    if targetWidth > imageWidth
      score = (score * (1.3 + (2 * targetWidth) / imageWidth))
    if targetHeight > imageHeight
      score = (score * (1.3 + (2 * targetHeight) / imageHeight))
    return score

  ImageMixin =
    closestImage: (list, width, height) ->
      return null unless list
      bestScore = 0
      bestImage = null
      list = list.sort (a,b) -> if a.width < b.width then -1 else 1
      list.some (image) ->
        if image.width >= width
          return bestImage = image
        #if (score = closenessScore(image.width, image.height, width, height)) > bestScore
        #  bestScore = score
        #  bestImage = image
      return bestImage
